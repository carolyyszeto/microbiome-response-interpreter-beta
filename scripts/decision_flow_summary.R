#!/usr/bin/env Rscript

# decision_flow_summary.R
# Reader-friendly decision-flow summary for magnitude-coherence outputs.
# This script is an interpretation aid, not a clinical decision tool.

args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag, default = NULL) {
  hit <- which(args == flag)
  if (length(hit) == 0 || hit[length(hit)] == length(args)) return(default)
  args[hit[length(hit)] + 1]
}

has_flag <- function(flag) any(args == flag)

usage <- function() {
  cat(paste0(
    "Usage:\n",
    "  Rscript decision_flow_summary.R --group_geometry group_geometry.tsv --outdir out [options]\n\n",
    "Options:\n",
    "  --magnitude_col COL        Magnitude column name. Default: auto-detect.\n",
    "  --coherence_col COL        Coherence column name. Default: auto-detect.\n",
    "  --group_col COL            Group column name. Default: auto-detect.\n",
    "  --magnitude_threshold X    Numeric high/low threshold. Default: median across groups.\n",
    "  --coherence_threshold X    Numeric high/low threshold. Default: 0.10.\n",
    "  --coherence_null_col COL   Optional permutation-null mean column.\n",
    "  --coherence_gap_col COL    Optional observed-minus-null gap column.\n",
    "  --endpoint_note TEXT       Optional endpoint or layer caveat.\n",
    "  --help                     Show this message.\n\n",
    "Outputs:\n",
    "  decision_flow_summary.tsv\n",
    "  decision_flow_summary.md\n"
  ))
}

if (has_flag("--help") || length(args) == 0) {
  usage()
  quit(status = 0)
}

group_geometry_path <- get_arg("--group_geometry")
outdir <- get_arg("--outdir", ".")
if (is.null(group_geometry_path)) stop("Missing required --group_geometry")
if (!file.exists(group_geometry_path)) stop("File not found: ", group_geometry_path)
if (!dir.exists(outdir)) dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

read_table <- function(path) {
  utils::read.delim(path, check.names = FALSE, stringsAsFactors = FALSE)
}

dat <- read_table(group_geometry_path)
if (nrow(dat) == 0) stop("Input table has no rows")

pick_col <- function(candidates, user_col = NULL) {
  if (!is.null(user_col)) {
    if (!user_col %in% names(dat)) stop("Requested column not found: ", user_col)
    return(user_col)
  }
  hit <- candidates[candidates %in% names(dat)]
  if (length(hit) == 0) return(NULL)
  hit[1]
}

group_col <- pick_col(c("group", "arm", "condition", "intervention", "contrast"), get_arg("--group_col"))
mag_col <- pick_col(c("mean_magnitude", "magnitude_mean", "median_magnitude", "aitchison_magnitude", "magnitude"), get_arg("--magnitude_col"))
coh_col <- pick_col(c("mean_cosine", "mean_coherence", "coherence", "directional_coherence", "loo_coherence", "mean_alignment"), get_arg("--coherence_col"))
null_col <- pick_col(c("permutation_null_mean", "null_mean", "coherence_null_mean"), get_arg("--coherence_null_col"))
gap_col <- pick_col(c("coherence_gap", "observed_minus_null", "mean_cosine_gap", "coherence_observed_minus_null"), get_arg("--coherence_gap_col"))

if (is.null(group_col)) {
  group_col <- ".group"
  dat[[group_col]] <- paste0("group_", seq_len(nrow(dat)))
}
if (is.null(mag_col)) stop("Could not auto-detect a magnitude column. Use --magnitude_col.")
if (is.null(coh_col)) stop("Could not auto-detect a coherence column. Use --coherence_col.")

as_num <- function(x, name) {
  y <- suppressWarnings(as.numeric(x))
  if (all(is.na(y))) stop("Column is not numeric: ", name)
  y
}

mag <- as_num(dat[[mag_col]], mag_col)
coh <- as_num(dat[[coh_col]], coh_col)

mag_threshold_arg <- get_arg("--magnitude_threshold")
coh_threshold_arg <- get_arg("--coherence_threshold")
mag_threshold <- if (is.null(mag_threshold_arg)) stats::median(mag, na.rm = TRUE) else as.numeric(mag_threshold_arg)
coh_threshold <- if (is.null(coh_threshold_arg)) 0.10 else as.numeric(coh_threshold_arg)
if (!is.finite(mag_threshold)) stop("Invalid magnitude threshold")
if (!is.finite(coh_threshold)) stop("Invalid coherence threshold")

mag_label <- ifelse(mag >= mag_threshold, "higher magnitude", "lower magnitude")
coh_label <- ifelse(coh >= coh_threshold, "higher coherence", "weak coherence")

classify <- function(mag_high, coh_high) {
  if (!mag_high && !coh_high) return("limited movement with weak alignment")
  if (mag_high && !coh_high) return("large movement with weak alignment")
  if (!mag_high && coh_high) return("magnitude-limited organized movement")
  "large coordinated movement"
}

interpretation <- function(state) {
  switch(state,
    "limited movement with weak alignment" = "Little evidence of organized group-level remodeling in the tested feature space.",
    "large movement with weak alignment" = "Participants moved, but not in a shared direction; heterogeneous or subgroup-specific trajectories should be considered.",
    "magnitude-limited organized movement" = "A modest but directionally organized response may be present if robustness checks support it.",
    "large coordinated movement" = "A stronger coordinated response is plausible in this feature space if sensitivity and endpoint checks are stable.",
    "Interpret conservatively within the tested feature space."
  )
}

next_check <- function(state) {
  switch(state,
    "limited movement with weak alignment" = "Check pairability, endpoint choice, feature-space suitability, exposure strength, and simulation-based operating context.",
    "large movement with weak alignment" = "Inspect individual trajectories, baseline dependence, subgroup structure, PERMDISP/dispersion context, adherence, and leave-one-out influence.",
    "magnitude-limited organized movement" = "Verify pseudocount sensitivity, bootstrap stability, leave-one-out stability, endpoint alignment, and targeted biological markers.",
    "large coordinated movement" = "Prioritize endpoint-aligned replication, feature-space robustness, zero-handling sensitivity, and independent host or functional-context support.",
    "Add sensitivity and endpoint checks before stronger interpretation."
  )
}

state <- mapply(function(m, c) classify(m >= mag_threshold, c >= coh_threshold), mag, coh, USE.NAMES = FALSE)
endpoint_note <- get_arg("--endpoint_note", "Interpretation is feature-space and endpoint specific.")

out <- data.frame(
  group = dat[[group_col]],
  magnitude = mag,
  coherence = coh,
  magnitude_threshold = mag_threshold,
  coherence_threshold = coh_threshold,
  magnitude_label = mag_label,
  coherence_label = coh_label,
  decision_state = state,
  practical_interpretation = vapply(state, interpretation, character(1)),
  recommended_next_check = vapply(state, next_check, character(1)),
  claim_boundary = "Response-organization interpretation only; not clinical efficacy, prediction, or mechanism.",
  stringsAsFactors = FALSE
)

if (!is.null(null_col)) out$coherence_null <- suppressWarnings(as.numeric(dat[[null_col]]))
if (!is.null(gap_col)) out$coherence_gap <- suppressWarnings(as.numeric(dat[[gap_col]]))

utils::write.table(out, file.path(outdir, "decision_flow_summary.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)

md_path <- file.path(outdir, "decision_flow_summary.md")
con <- file(md_path, open = "wt")
writeLines("# Decision-Flow Summary", con)
writeLines("", con)
writeLines(paste0("Magnitude threshold: ", signif(mag_threshold, 4), ". Coherence threshold: ", signif(coh_threshold, 4), "."), con)
writeLines(paste0("Endpoint note: ", endpoint_note), con)
writeLines("", con)
for (i in seq_len(nrow(out))) {
  writeLines(paste0("## ", out$group[i]), con)
  writeLines("", con)
  writeLines(paste0("- Pattern: ", out$decision_state[i]), con)
  writeLines(paste0("- Interpretation: ", out$practical_interpretation[i]), con)
  writeLines(paste0("- Suggested next check: ", out$recommended_next_check[i]), con)
  writeLines(paste0("- Boundary: ", out$claim_boundary[i]), con)
  writeLines("", con)
}
writeLines("This decision flow is an accessibility layer for response-geometry interpretation. It is not a clinical decision tree or validated responder classifier.", con)
close(con)

cat("Wrote decision flow outputs to ", outdir, "\n", sep = "")
