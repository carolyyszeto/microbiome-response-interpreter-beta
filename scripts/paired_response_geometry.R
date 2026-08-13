script_file <- normalizePath(
  sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)[1]),
  winslash = "/",
  mustWork = FALSE
)
source(file.path(dirname(script_file), "backend_common.R"))

usage <- function() {
  cat(
    paste(
      "Usage:",
      "  Rscript skills/microbiome-response-interpreter-v6.5/scripts/paired_response_geometry.R",
      "    --metadata PATH",
      "    --outdir PATH",
      "    [--counts PATH | --feature_table PATH | --clr PATH | --distance PATH]",
      "    [--pairing_map PATH]",
      "    [--input-format auto|matrix|long]",
      "    [--sample-col NAME]",
      "    [--feature-col NAME]",
      "    [--value-col NAME]",
      "    [--samples-in-rows auto|true|false]",
      "    [--subject-col NAME]",
      "    [--group-col NAME]",
      "    [--phase-col NAME]",
      "    [--stage-col NAME]",
      "    [--method pseudocount|bayes]",
      "    [--pseudocount 0.5]",
      sep = "\n"
    ),
    "\n"
  )
}

read_clr_tsv <- function(path) {
  df <- readr::read_tsv(path, show_col_types = FALSE)
  mat <- coerce_df_to_numeric_matrix(as.data.frame(df))
  rownames(mat) <- normalize_id(rownames(mat))
  mat
}

build_geometry_from_clr <- function(clr_mat, pairs) {
  vec_df <- compute_subject_vectors(clr_mat, pairs)
  if (nrow(vec_df) == 0) {
    return(list(vectors = tibble(), summary = tibble(), coords = tibble()))
  }

  vec_tbl <- geometry_directional_summary(vec_df)

  group_tbl <- vec_df %>%
    group_by(group) %>%
    group_modify(~{
      vmat <- do.call(rbind, .x$vector)
      mu <- colMeans(vmat)
      tibble(
        n_subjects = nrow(vmat),
        mean_vector_magnitude = sqrt(sum(mu * mu)),
        mean_subject_magnitude = mean(sqrt(rowSums(vmat * vmat))),
        mean_loo_reference_cosine = mean(compute_loo_cosines(vmat), na.rm = TRUE),
        mean_legacy_full_sample_cosine = mean(compute_group_cosines(vmat), na.rm = TRUE)
      )
    }) %>%
    ungroup()

  dist_obj <- aitchison_dist_from_clr(clr_mat)
  coords <- cmdscale_tibble(dist_obj, k = 2)

  list(vectors = vec_tbl, summary = group_tbl, coords = coords)
}

build_geometry_from_distance <- function(dist_obj, metadata_prepared) {
  coords <- cmdscale_tibble(dist_obj, k = 2)
  df <- coords %>%
    left_join(metadata_prepared, by = c("SampleID" = "sample_id_norm"))

  wide <- df %>%
    select(subject_id, group, phase_std, PC1, PC2) %>%
    filter(phase_std %in% c("Before", "After")) %>%
    group_by(subject_id, group, phase_std) %>%
    summarise(PC1 = mean(PC1, na.rm = TRUE), PC2 = mean(PC2, na.rm = TRUE), .groups = "drop") %>%
    pivot_wider(names_from = phase_std, values_from = c(PC1, PC2), names_sep = "_")

  if (nrow(wide) == 0) {
    return(list(vectors = tibble(), summary = tibble(), coords = coords))
  }

  vec_tbl <- wide %>%
    transmute(
      subject_id = subject_id,
      group = group,
      dx = PC1_After - PC1_Before,
      dy = PC2_After - PC2_Before,
      magnitude = sqrt(dx^2 + dy^2)
    )

  group_dir <- vec_tbl %>%
    group_by(group) %>%
    summarise(mx = mean(dx), my = mean(dy), n_subjects = n(), .groups = "drop")

  vec_tbl <- vec_tbl %>%
    left_join(group_dir, by = "group") %>%
    group_by(group) %>% group_modify(~{
      v <- as.matrix(.x[, c("dx", "dy")]);
      tibble(subject_id = .x$subject_id, group = .x$group, magnitude = .x$magnitude,
        loo_reference_cosine = compute_loo_cosines(v),
        legacy_full_sample_mean_cosine = compute_group_cosines(v))
    }) %>% ungroup()

  group_tbl <- vec_tbl %>%
    group_by(group) %>%
    summarise(
      n_subjects = n(),
      mean_vector_magnitude = mean(magnitude, na.rm = TRUE),
      mean_subject_magnitude = mean(magnitude, na.rm = TRUE),
      mean_loo_reference_cosine = mean(loo_reference_cosine, na.rm = TRUE),
      mean_legacy_full_sample_cosine = mean(legacy_full_sample_mean_cosine, na.rm = TRUE),
      .groups = "drop"
    )

  list(vectors = vec_tbl, summary = group_tbl, coords = coords)
}

main <- function() {
  opts <- parse_cli_args()
  if (as_flag(opts$help)) {
    usage()
    return(invisible(NULL))
  }

  require_args(opts, c("metadata", "outdir"))
  opts$counts <- opts$counts %||% opts$feature_table
  if (sum(!vapply(list(opts$counts, opts$clr, opts$distance), is.null, logical(1))) != 1) {
    stop("Provide exactly one of --counts/--feature_table, --clr, or --distance.", call. = FALSE)
  }

  outdir <- ensure_outdir(opts$outdir)
  metadata <- read_metadata_table(opts$metadata)
  prepared <- prepare_metadata(
    metadata,
    sample_col = opts$sample_col %||% "auto",
    subject_col = opts$subject_col %||% "auto",
    group_col = opts$group_col %||% "auto",
    phase_col = opts$phase_col %||% "auto",
    stage_col = opts$stage_col %||% "auto"
  )
  pairs <- if (!is.null(opts$pairing_map)) read_pairing_map(opts$pairing_map) else infer_pairs(prepared)

  if (nrow(pairs) == 0) {
    stop("No unambiguous Before/After pairs were found in the metadata or pairing map.", call. = FALSE)
  }

  if (!is.null(opts$counts)) {
    counts <- read_counts_matrix(
      path = opts$counts,
      input_format = opts$input_format %||% "auto",
      sample_col = opts$sample_col %||% "SampleID",
      feature_col = opts$feature_col %||% "Feature",
      value_col = opts$value_col %||% "Value",
      samples_in_rows = opts$samples_in_rows %||% "auto"
    )
    common <- intersect(rownames(counts), prepared$sample_id_norm)
    counts <- counts[common, , drop = FALSE]
    method <- tolower(opts$method %||% "pseudocount")
    pseudocount <- as_number(opts$pseudocount, default = 0.5)
    clr_res <- compute_clr_and_aitchison(counts, method = method, pseudocount = pseudocount)
    clr_mat <- clr_res$clr
    rownames(clr_mat) <- rownames(counts)
    geometry <- build_geometry_from_clr(clr_mat, pairs)
    space <- "clr"
  } else if (!is.null(opts$clr)) {
    clr_mat <- read_clr_tsv(opts$clr)
    common <- intersect(rownames(clr_mat), prepared$sample_id_norm)
    clr_mat <- clr_mat[common, , drop = FALSE]
    geometry <- build_geometry_from_clr(clr_mat, pairs)
    space <- "clr"
  } else {
    dist_obj <- read_distance_object(opts$distance)
    geometry <- build_geometry_from_distance(dist_obj, prepared)
    space <- "pcoa_from_distance"
  }

  if (nrow(geometry$vectors) == 0) {
    stop("No paired vectors could be computed after aligning samples.", call. = FALSE)
  }

  write_tsv_safe(geometry$vectors, file.path(outdir, "paired_vectors.tsv"))
  write_tsv_safe(geometry$summary, file.path(outdir, "group_geometry.tsv"))
  write_tsv_safe(geometry$coords, file.path(outdir, "sample_geometry_coords.tsv"))
  write_tsv_safe(pairs, file.path(outdir, "pair_mapping.tsv"))

  summary_tbl <- tibble(
    metric = c("space", "n_pairs", "n_groups"),
    value = c(space, nrow(geometry$vectors), dplyr::n_distinct(geometry$vectors$group))
  )
  write_tsv_safe(summary_tbl, file.path(outdir, "paired_response_geometry_summary.tsv"))
}

main()
