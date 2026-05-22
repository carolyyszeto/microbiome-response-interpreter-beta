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
      "  Rscript skills/microbiome-response-interpreter-v6.5/scripts/check_inputs.R",
      "    --outdir PATH",
      "    [--counts PATH | --feature_table PATH]",
      "    [--metadata PATH]",
      "    [--pairing_map PATH]",
      "    [--distance PATH]",
      "    [--input-format auto|matrix|long]",
      "    [--sample-col NAME]",
      "    [--feature-col NAME]",
      "    [--value-col NAME]",
      "    [--samples-in-rows auto|true|false]",
      "    [--subject-col NAME]",
      "    [--group-col NAME]",
      "    [--phase-col NAME]",
      "    [--stage-col NAME]",
      sep = "\n"
    ),
    "\n"
  )
}

main <- function() {
  opts <- parse_cli_args()
  if (as_flag(opts$help)) {
    usage()
    return(invisible(NULL))
  }

  require_args(opts, c("outdir"))
  opts$counts <- opts$counts %||% opts$feature_table
  outdir <- ensure_outdir(opts$outdir)

  messages <- list()
  summary_rows <- list()
  pairs <- tibble()

  counts <- NULL
  metadata <- NULL
  prepared <- NULL
  dist_obj <- NULL

  if (!is.null(opts$counts)) {
    counts <- read_counts_matrix(
      path = opts$counts,
      input_format = opts$input_format %||% "auto",
      sample_col = opts$sample_col %||% "SampleID",
      feature_col = opts$feature_col %||% "Feature",
      value_col = opts$value_col %||% "Value",
      samples_in_rows = opts$samples_in_rows %||% "auto"
    )
    summary_rows[[length(summary_rows) + 1L]] <- summarise_count_matrix(counts) %>% mutate(component = "counts")
  } else {
    messages[[length(messages) + 1L]] <- tibble(level = "warning", code = "COUNTS_MISSING", message = "No counts input supplied.")
  }

  if (!is.null(opts$metadata)) {
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

    summary_rows[[length(summary_rows) + 1L]] <- tibble(
      component = "metadata",
      metric = c("n_rows", "n_unique_samples", "n_subjects", "n_groups", "n_before_after_pairs"),
      value = c(
        nrow(prepared),
        dplyr::n_distinct(prepared$sample_id_norm),
        dplyr::n_distinct(prepared$subject_id[!is.na(prepared$subject_id)]),
        dplyr::n_distinct(prepared$group[!is.na(prepared$group)]),
        nrow(pairs)
      )
    )

    if (any(grepl("clinical|outcome|ms_change|homa|tg_hdl", tolower(colnames(metadata))))) {
      messages[[length(messages) + 1L]] <- tibble(level = "info", code = "CLINICAL_COLUMNS_PRESENT", message = "Clinical or outcome columns were detected but will not be used by the reusable backend.")
    }
  } else {
    messages[[length(messages) + 1L]] <- tibble(level = "warning", code = "METADATA_MISSING", message = "No metadata input supplied.")
  }

  if (!is.null(opts$distance)) {
    dist_obj <- read_distance_object(opts$distance)
    summary_rows[[length(summary_rows) + 1L]] <- tibble(
      component = "distance",
      metric = c("n_samples", "n_pairwise_values"),
      value = c(attr(dist_obj, "Size"), length(dist_obj))
    )
  }

  if (!is.null(counts) && !is.null(prepared)) {
    overlap_n <- length(intersect(rownames(counts), prepared$sample_id_norm))
    summary_rows[[length(summary_rows) + 1L]] <- tibble(component = "overlap", metric = "counts_metadata_overlap", value = overlap_n)
    if (overlap_n == 0) {
      messages[[length(messages) + 1L]] <- tibble(level = "error", code = "NO_COUNTS_METADATA_OVERLAP", message = "Counts and metadata share no normalized sample IDs.")
    }
  }

  if (!is.null(dist_obj) && !is.null(prepared)) {
    dist_ids <- normalize_id(rownames(as.matrix(dist_obj)))
    overlap_n <- length(intersect(dist_ids, prepared$sample_id_norm))
    summary_rows[[length(summary_rows) + 1L]] <- tibble(component = "overlap", metric = "distance_metadata_overlap", value = overlap_n)
    if (overlap_n == 0) {
      messages[[length(messages) + 1L]] <- tibble(level = "error", code = "NO_DISTANCE_METADATA_OVERLAP", message = "Distance input and metadata share no normalized sample IDs.")
    }
  }

  summary_tbl <- bind_rows(summary_rows)
  messages_tbl <- bind_rows(messages)
  if (nrow(messages_tbl) == 0) {
    messages_tbl <- tibble(level = "info", code = "OK", message = "No validation messages.")
  }

  write_tsv_safe(summary_tbl, file.path(outdir, "check_inputs_summary.tsv"))
  write_tsv_safe(messages_tbl, file.path(outdir, "check_inputs_messages.tsv"))
  if (nrow(pairs) > 0) {
    write_tsv_safe(pairs, file.path(outdir, "check_inputs_pairs.tsv"))
  }
}

main()
