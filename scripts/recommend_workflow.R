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
      "  Rscript skills/microbiome-response-interpreter-v6.5/scripts/recommend_workflow.R",
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

  has_counts <- !is.null(opts$counts)
  has_metadata <- !is.null(opts$metadata)
  has_distance <- !is.null(opts$distance)
  has_pairs <- FALSE

  notes <- list()
  if (has_metadata) {
    metadata <- read_metadata_table(opts$metadata)
    prepared <- prepare_metadata(
      metadata,
      sample_col = opts$sample_col %||% "auto",
      subject_col = opts$subject_col %||% "auto",
      group_col = opts$group_col %||% "auto",
      phase_col = opts$phase_col %||% "auto",
      stage_col = opts$stage_col %||% "auto"
    )
    has_pairs <- if (!is.null(opts$pairing_map)) nrow(read_pairing_map(opts$pairing_map)) > 0 else nrow(infer_pairs(prepared)) > 0
    if (any(grepl("clinical|outcome|ms_change|homa|tg_hdl", tolower(colnames(metadata))))) {
      notes[[length(notes) + 1L]] <- tibble(note = "Clinical or outcome columns were detected but are intentionally excluded from the reusable workflow.")
    }
  }

  recommendations <- list(
    tibble(
      priority = 1L,
      module = "check_inputs",
      enabled = TRUE,
      rationale = "Always validate file shapes, sample overlap, and pairability first.",
      required_args = "--outdir plus any provided input paths"
    )
  )

  if (has_counts) {
    recommendations[[length(recommendations) + 1L]] <- tibble(
      priority = 2L,
      module = "compute_clr_aitchison",
      enabled = TRUE,
      rationale = "Counts are available, so CLR transforms and Aitchison distances can be computed directly from the source table.",
      required_args = "--counts/--feature_table --outdir"
    )
  }

  if (has_pairs) {
    recommendations[[length(recommendations) + 1L]] <- tibble(
      priority = 3L,
      module = "paired_response_geometry",
      enabled = TRUE,
      rationale = if (has_counts) {
        "Before/After pairs and counts are available, so subject response vectors can be computed in CLR space."
      } else if (has_distance) {
        "Before/After pairs and a distance object are available, so subject response vectors can be approximated in PCoA space from the supplied distance."
      } else {
        "Before/After pairability is explicit, so paired response geometry is available once counts/CLR or a distance object is supplied."
      },
      required_args = if (has_counts) {
        "--counts/--feature_table --metadata --outdir"
      } else if (has_distance) {
        "--distance --metadata --outdir"
      } else {
        "--counts/--feature_table or --clr or --distance, plus --metadata and --outdir"
      }
    )
  } else {
    recommendations[[length(recommendations) + 1L]] <- tibble(
      priority = 3L,
      module = "paired_response_geometry",
      enabled = FALSE,
      rationale = "This module needs metadata with unambiguous Before/After pairs plus either counts/CLR or a distance object.",
      required_args = "--metadata plus paired sample information"
    )
  }

  recommendations[[length(recommendations) + 1L]] <- tibble(
    priority = 4L,
    module = "export_summary",
    enabled = TRUE,
    rationale = "The backend should always finish by writing a machine-readable manifest and run summary.",
    required_args = "--outdir"
  )

  rec_tbl <- bind_rows(recommendations) %>% arrange(priority, module)
  notes_tbl <- if (length(notes) > 0) bind_rows(notes) else tibble(note = "No additional notes.")

  write_tsv_safe(rec_tbl, file.path(outdir, "workflow_recommendation.tsv"))
  write_tsv_safe(notes_tbl, file.path(outdir, "workflow_notes.tsv"))
}

main()
