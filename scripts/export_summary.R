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
      "  Rscript skills/microbiome-response-interpreter-v6.5/scripts/export_summary.R",
      "    --outdir PATH | --run_dir PATH",
      "    [--check-inputs-summary PATH]",
      "    [--workflow-summary PATH]",
      "    [--compute-summary PATH]",
      "    [--geometry-summary PATH]",
      sep = "\n"
    ),
    "\n"
  )
}

read_if_exists <- function(path) {
  if (!is.null(path) && file.exists(path)) {
    return(readr::read_tsv(path, show_col_types = FALSE))
  }
  NULL
}

main <- function() {
  opts <- parse_cli_args()
  if (as_flag(opts$help)) {
    usage()
    return(invisible(NULL))
  }

  opts$outdir <- opts$outdir %||% opts$run_dir
  require_args(opts, c("outdir"))
  outdir <- ensure_outdir(opts$outdir)

  check_tbl <- read_if_exists(opts$check_inputs_summary %||% file.path(outdir, "check_inputs_summary.tsv"))
  workflow_tbl <- read_if_exists(opts$workflow_summary %||% file.path(outdir, "workflow_recommendation.tsv"))
  compute_tbl <- read_if_exists(opts$compute_summary %||% file.path(outdir, "compute_clr_aitchison_summary.tsv"))
  geometry_tbl <- read_if_exists(opts$geometry_summary %||% file.path(outdir, "paired_response_geometry_summary.tsv"))

  summary_rows <- list(
    tibble(module = "check_inputs", present = !is.null(check_tbl), detail = if (is.null(check_tbl)) "missing" else "summary_found"),
    tibble(module = "recommend_workflow", present = !is.null(workflow_tbl), detail = if (is.null(workflow_tbl)) "missing" else "summary_found"),
    tibble(module = "compute_clr_aitchison", present = !is.null(compute_tbl), detail = if (is.null(compute_tbl)) "missing" else paste(compute_tbl$method, collapse = ",")),
    tibble(module = "paired_response_geometry", present = !is.null(geometry_tbl), detail = if (is.null(geometry_tbl)) "missing" else paste(geometry_tbl$value, collapse = ","))
  )

  files <- list.files(outdir, recursive = TRUE, full.names = TRUE)
  files <- files[file.info(files)$isdir %in% FALSE]
  rel_files <- sub(paste0("^", gsub("([\\\\/\\.^$|?*+(){}])", "\\\\\\1", normalizePath(outdir, winslash = "/", mustWork = FALSE)), "/?"), "", normalizePath(files, winslash = "/", mustWork = FALSE))

  manifest_tbl <- tibble(
    path = rel_files,
    extension = tolower(tools::file_ext(rel_files)),
    size_bytes = file.info(files)$size
  ) %>%
    arrange(path)

  write_tsv_safe(bind_rows(summary_rows), file.path(outdir, "backend_summary.tsv"))
  write_tsv_safe(manifest_tbl, file.path(outdir, "backend_manifest.tsv"))
  write_tsv_safe(manifest_tbl, file.path(outdir, "run_manifest.tsv"))
}

main()
