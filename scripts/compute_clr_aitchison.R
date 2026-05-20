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
      "  Rscript skills/microbiome-response-interpreter-v6/scripts/compute_clr_aitchison.R",
      "    --counts PATH | --feature_table PATH",
      "    --outdir PATH",
      "    [--input-format auto|matrix|long]",
      "    [--sample-col NAME]",
      "    [--feature-col NAME]",
      "    [--value-col NAME]",
      "    [--samples-in-rows auto|true|false]",
      "    [--method pseudocount|bayes|both]",
      "    [--pseudocount 0.5]",
      sep = "\n"
    ),
    "\n"
  )
}

write_matrix_tsv <- function(mat, path) {
  df <- as.data.frame(mat, check.names = FALSE)
  df <- data.frame(sample_id = rownames(mat), df, check.names = FALSE)
  write_tsv_safe(df, path)
}

main <- function() {
  opts <- parse_cli_args()
  if (as_flag(opts$help)) {
    usage()
    return(invisible(NULL))
  }

  opts$counts <- opts$counts %||% opts$feature_table
  require_args(opts, c("counts", "outdir"))
  outdir <- ensure_outdir(opts$outdir)

  counts <- read_counts_matrix(
    path = opts$counts,
    input_format = opts$input_format %||% "auto",
    sample_col = opts$sample_col %||% "SampleID",
    feature_col = opts$feature_col %||% "Feature",
    value_col = opts$value_col %||% "Value",
    samples_in_rows = opts$samples_in_rows %||% "auto"
  )

  method_arg <- tolower(opts$method %||% "both")
  methods <- switch(
    method_arg,
    pseudocount = "pseudocount",
    bayes = "bayes",
    both = c("pseudocount", "bayes"),
    stop("Unsupported method: ", method_arg, call. = FALSE)
  )

  pseudocount <- as_number(opts$pseudocount, default = 0.5)
  summary_rows <- list()

  for (method_name in methods) {
    res <- compute_clr_and_aitchison(counts, method = method_name, pseudocount = pseudocount)
    clr_mat <- res$clr
    rownames(clr_mat) <- rownames(counts)

    clr_path <- file.path(outdir, paste0("clr_", method_name, ".tsv"))
    dist_path <- file.path(outdir, paste0("aitchison_", method_name, ".tsv"))

    write_matrix_tsv(clr_mat, clr_path)
    write_matrix_tsv(as.matrix(res$dist), dist_path)

    summary_rows[[length(summary_rows) + 1L]] <- tibble(
      method = method_name,
      method_label = res$method_label,
      used_zcompositions = res$used_zcompositions,
      n_samples = nrow(clr_mat),
      n_features = ncol(clr_mat),
      pseudocount = pseudocount,
      clr_file = basename(clr_path),
      distance_file = basename(dist_path)
    )
  }

  summary_tbl <- bind_rows(summary_rows)
  write_tsv_safe(summary_tbl, file.path(outdir, "compute_clr_aitchison_summary.tsv"))
}

main()
