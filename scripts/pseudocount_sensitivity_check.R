script_file <- normalizePath(
  sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)[1]),
  winslash = "/",
  mustWork = FALSE
)
source(file.path(dirname(script_file), "backend_common.R"))

usage <- function() {
  cat(paste(
    "Usage:",
    "  Rscript scripts/pseudocount_sensitivity_check.R",
    "    --feature_table PATH",
    "    --metadata PATH",
    "    --outdir PATH",
    "    [--pairing_map PATH]",
    "    [--pseudocounts 0.5,1.0]",
    "    [--reference_pseudocount 0.5]",
    "    [--input-format auto|matrix|long]",
    "    [--sample-col NAME]",
    "    [--feature-col NAME]",
    "    [--value-col NAME]",
    "    [--samples-in-rows auto|true|false]",
    "    [--subject-col NAME]",
    "    [--group-col NAME]",
    "    [--phase-col NAME]",
    "    [--stage-col NAME]",
    sep = "\n"), "\n")
}

parse_number_grid <- function(x, default = c(0.5, 1.0)) {
  if (is.null(x) || identical(x, "")) return(default)
  vals <- suppressWarnings(as.numeric(strsplit(as.character(x), ",", fixed = TRUE)[[1]]))
  vals <- vals[is.finite(vals) & vals > 0]
  if (length(vals) == 0) stop("No valid positive pseudocount values were supplied.", call. = FALSE)
  unique(vals)
}

compute_geometry_for_pseudocount <- function(counts, pairs, pseudocount) {
  clr_res <- compute_clr_and_aitchison(counts, method = "pseudocount", pseudocount = pseudocount)
  clr_mat <- clr_res$clr
  rownames(clr_mat) <- rownames(counts)
  vec_df <- compute_subject_vectors(clr_mat, pairs)
  if (nrow(vec_df) == 0) stop("No paired vectors could be computed after aligning samples.", call. = FALSE)

  subject_tbl <- geometry_directional_summary(vec_df) %>%
    mutate(pseudocount = pseudocount, .before = 1)

  group_tbl <- vec_df %>%
    group_by(group) %>%
    group_modify(~{
      vmat <- do.call(rbind, .x$vector)
      mu <- colMeans(vmat)
      tibble(
        n_subjects = nrow(vmat),
        mean_vector_magnitude = sqrt(sum(mu * mu)),
        mean_subject_magnitude = mean(sqrt(rowSums(vmat * vmat))),
        median_subject_magnitude = stats::median(sqrt(rowSums(vmat * vmat))),
        mean_loo_reference_cosine = mean(compute_loo_cosines(vmat), na.rm = TRUE),
        median_loo_reference_cosine = stats::median(compute_loo_cosines(vmat), na.rm = TRUE),
        mean_legacy_full_sample_cosine = mean(compute_group_cosines(vmat), na.rm = TRUE)
      )
    }) %>%
    ungroup() %>%
    mutate(pseudocount = pseudocount, .before = 1)

  list(subject = subject_tbl, group = group_tbl)
}

main <- function() {
  opts <- parse_cli_args()
  if (as_flag(opts$help)) {
    usage()
    return(invisible(NULL))
  }

  require_args(opts, c("metadata", "outdir"))
  feature_path <- opts$feature_table %||% opts$counts
  if (is.null(feature_path)) stop("Provide --feature_table or --counts.", call. = FALSE)

  outdir <- ensure_outdir(opts$outdir)
  pseudocounts <- parse_number_grid(opts$pseudocounts %||% "0.5,1.0")
  reference_pc <- as_number(opts$reference_pseudocount, default = pseudocounts[1])
  if (!(reference_pc %in% pseudocounts)) pseudocounts <- unique(c(reference_pc, pseudocounts))

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
  if (nrow(pairs) == 0) stop("No unambiguous Before/After pairs were found.", call. = FALSE)

  counts <- read_counts_matrix(
    path = feature_path,
    input_format = opts$input_format %||% "auto",
    sample_col = opts$sample_col %||% "SampleID",
    feature_col = opts$feature_col %||% "Feature",
    value_col = opts$value_col %||% "Value",
    samples_in_rows = opts$samples_in_rows %||% "auto"
  )
  rownames(counts) <- normalize_id(rownames(counts))
  common <- intersect(rownames(counts), unique(c(pairs$Before, pairs$After)))
  counts <- counts[common, , drop = FALSE]
  pairs <- pairs %>% filter(Before %in% rownames(counts), After %in% rownames(counts))
  if (nrow(pairs) == 0) stop("No pairs remain after aligning feature table and pairing map.", call. = FALSE)

  results <- lapply(pseudocounts, function(pc) compute_geometry_for_pseudocount(counts, pairs, pc))
  subject_tbl <- bind_rows(lapply(results, `[[`, "subject"))
  group_tbl <- bind_rows(lapply(results, `[[`, "group"))

  ref_tbl <- group_tbl %>%
    filter(abs(pseudocount - reference_pc) < .Machine$double.eps^0.5) %>%
    select(group, ref_mean_subject_magnitude = mean_subject_magnitude, ref_mean_loo_reference_cosine = mean_loo_reference_cosine)

  compare_tbl <- group_tbl %>%
    left_join(ref_tbl, by = "group") %>%
    mutate(
      reference_pseudocount = reference_pc,
      delta_mean_subject_magnitude = mean_subject_magnitude - ref_mean_subject_magnitude,
      delta_mean_loo_reference_cosine = mean_loo_reference_cosine - ref_mean_loo_reference_cosine,
      relative_delta_magnitude = delta_mean_subject_magnitude / ifelse(abs(ref_mean_subject_magnitude) < 1e-12, NA_real_, ref_mean_subject_magnitude),
      qualitative_note = case_when(
        is.na(delta_mean_loo_reference_cosine) ~ "not_evaluable",
        TRUE ~ "descriptive_comparison_no_validated_cutoff"
      )
    )

  write_tsv_safe(subject_tbl, file.path(outdir, "pseudocount_sensitivity_subject.tsv"))
  write_tsv_safe(group_tbl, file.path(outdir, "pseudocount_sensitivity_group.tsv"))
  write_tsv_safe(compare_tbl, file.path(outdir, "pseudocount_sensitivity_comparison.tsv"))
  write_tsv_safe(pairs, file.path(outdir, "pair_mapping_used.tsv"))

  note <- c(
    "# Pseudocount sensitivity note",
    "",
    paste0("Reference pseudocount: ", reference_pc),
    paste0("Pseudocount grid: ", paste(pseudocounts, collapse = ", ")),
    paste0("Paired subjects analyzed: ", nrow(pairs)),
    paste0("Feature count: ", ncol(counts)),
    "",
    "Interpretation boundary: this is a targeted pseudocount sensitivity check under the supplied pairings, endpoint definitions, and feature table. It does not establish pseudocount invariance or replace a systematic zero-handling benchmark."
  )
  write_text_safe(note, file.path(outdir, "pseudocount_sensitivity_note.md"))
}

main()
