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
      "  Rscript skills/microbiome-response-interpreter-v6/scripts/export_narrative_summary.R",
      "    --outdir PATH | --run_dir PATH",
      sep = "\n"
    ),
    "\n"
  )
}

make_comment_tbl <- function(module, comments) {
  comments <- comments[!is.na(comments) & nzchar(trimws(comments))]
  tibble(
    module = module,
    comment_order = seq_along(comments),
    comment = comments
  )
}

build_check_inputs_comments <- function(outdir) {
  tbl <- read_if_exists(file.path(outdir, "check_inputs_summary.tsv"))
  if (is.null(tbl)) {
    return(NULL)
  }
  tbl <- as_tibble(tbl)
  count_tbl <- tbl %>% filter(component == "counts")
  meta_tbl <- tbl %>% filter(component == "metadata")
  overlap_tbl <- tbl %>% filter(component == "overlap")
  dist_tbl <- tbl %>% filter(component == "distance")

  n_samples <- count_tbl$value[count_tbl$metric == "n_samples"][1]
  n_features <- count_tbl$value[count_tbl$metric == "n_features"][1]
  zero_fraction <- count_tbl$value[count_tbl$metric == "zero_fraction"][1]
  n_pairs <- meta_tbl$value[meta_tbl$metric == "n_before_after_pairs"][1]
  n_groups <- meta_tbl$value[meta_tbl$metric == "n_groups"][1]
  overlap_counts <- overlap_tbl$value[overlap_tbl$metric == "counts_metadata_overlap"][1]
  overlap_dist <- overlap_tbl$value[overlap_tbl$metric == "distance_metadata_overlap"][1]
  n_dist <- dist_tbl$value[dist_tbl$metric == "n_pairwise_values"][1]

  comments <- c(
    if (!is.na(n_samples) && !is.na(n_features)) {
      paste0("Input validation found ", n_samples, " samples across ", n_features, " features in the supplied abundance table.")
    },
    if (!is.na(zero_fraction)) {
      paste0("The count table is sparse, with approximately ", fmt_pct(zero_fraction), " zero entries, so compositional transforms should be interpreted as sparse-table summaries rather than dense profiles.")
    },
    if (!is.na(n_pairs) && !is.na(n_groups)) {
      paste0("Metadata support ", n_pairs, " Before/After pairs across ", n_groups, " groups.")
    },
    if (!is.na(overlap_counts)) {
      paste0("Counts and metadata overlap on ", overlap_counts, " normalized sample IDs.")
    },
    if (!is.na(n_dist) && !is.na(overlap_dist)) {
      paste0("A precomputed distance object is available with ", n_dist, " pairwise values and ", overlap_dist, " samples overlapping metadata.")
    }
  )
  make_comment_tbl("check_inputs", comments)
}

build_workflow_comments <- function(outdir) {
  tbl <- read_if_exists(file.path(outdir, "workflow_recommendation.tsv"))
  notes_tbl <- read_if_exists(file.path(outdir, "workflow_notes.tsv"))
  if (is.null(tbl)) {
    return(NULL)
  }
  tbl <- as_tibble(tbl)
  enabled <- tbl %>% filter(tolower(as.character(enabled)) %in% c("true", "1"))
  disabled <- tbl %>% filter(!(tolower(as.character(enabled)) %in% c("true", "1")))

  comments <- c(
    if (nrow(enabled) > 0) {
      paste0("The current data support the following backend path: ", paste(enabled$module, collapse = ", "), ".")
    },
    if ("paired_response_geometry" %in% enabled$module) {
      "Paired response geometry is enabled because the current inputs appear to support true Before/After linkage."
    },
    if ("compute_clr_aitchison" %in% enabled$module) {
      "CLR and Aitchison computation are recommended because count-like inputs are available."
    },
    if (nrow(disabled) > 0) {
      paste0("Modules not enabled by the current inputs remain out of scope for this run: ", paste(disabled$module, collapse = ", "), ".")
    },
    if (!is.null(notes_tbl) && nrow(notes_tbl) > 0) {
      paste0("Workflow notes: ", paste(notes_tbl$note, collapse = " "))
    }
  )
  make_comment_tbl("recommend_workflow", comments)
}

build_compute_comments <- function(outdir) {
  tbl <- read_if_exists(file.path(outdir, "compute_clr_aitchison_summary.tsv"))
  if (is.null(tbl)) {
    return(NULL)
  }
  tbl <- as_tibble(tbl)
  methods <- paste(tbl$method, collapse = ", ")
  method_values <- tolower(as.character(tbl$method))
  has_bayes <- any(grepl("bayes", method_values))
  used_z <- any(tolower(as.character(tbl$used_zcompositions)) %in% c("true", "1"))
  n_samples <- tbl$n_samples[1]
  n_features <- tbl$n_features[1]

  comments <- c(
    paste0("Compositional transforms were computed for ", n_samples, " samples across ", n_features, " features."),
    paste0("The following zero-handling routes were exported as machine-readable tables: ", methods, "."),
    if (has_bayes && used_z) {
      "A zCompositions-based multiplicative replacement route was available for the Bayesian-style transform."
    } else if (has_bayes) {
      "The Bayesian-style route used the packaged deterministic fallback because zCompositions was not required for this run."
    } else {
      "No Bayesian-style route was requested for this run."
    },
    "These outputs are backend truth tables and should be read as analysis intermediates rather than user-facing conclusions."
  )
  make_comment_tbl("compute_clr_aitchison", comments)
}

build_geometry_comments <- function(outdir) {
  summary_tbl <- read_if_exists(file.path(outdir, "paired_response_geometry_summary.tsv"))
  group_tbl <- read_if_exists(file.path(outdir, "group_geometry.tsv"))
  vec_tbl <- read_if_exists(file.path(outdir, "paired_vectors.tsv"))
  if (is.null(summary_tbl) || is.null(group_tbl) || is.null(vec_tbl)) {
    return(NULL)
  }

  summary_tbl <- as_tibble(summary_tbl)
  group_tbl <- as_tibble(group_tbl)
  vec_tbl <- as_tibble(vec_tbl)

  space <- summary_tbl$value[summary_tbl$metric == "space"][1]
  n_pairs <- summary_tbl$value[summary_tbl$metric == "n_pairs"][1]
  n_groups <- summary_tbl$value[summary_tbl$metric == "n_groups"][1]
  mag_range <- range(vec_tbl$magnitude, na.rm = TRUE)
  cos_range <- range(vec_tbl$mean_cosine, na.rm = TRUE)
  top_group <- group_tbl %>% arrange(desc(mean_cosine)) %>% slice(1)

  comments <- c(
    paste0("Paired response geometry was summarized in ", space, " space for ", n_pairs, " subject-level pairs across ", n_groups, " groups."),
    paste0("Subject-level response magnitudes span approximately ", fmt_num(mag_range[1]), " to ", fmt_num(mag_range[2]), " in the exported geometry units."),
    paste0("Within-group alignment scores span approximately ", fmt_num(cos_range[1], 3), " to ", fmt_num(cos_range[2], 3), "."),
    if (nrow(group_tbl) == 1) {
      paste0("The single exported group, ", top_group$group[[1]], ", has mean cosine ", fmt_num(top_group$mean_cosine[[1]], 3), ".")
    } else {
      paste0("At the group-summary level, ", top_group$group[[1]], " shows the highest average alignment in this run (mean cosine ", fmt_num(top_group$mean_cosine[[1]], 3), ").")
    },
    "These geometry summaries describe paired structure in the supplied data and do not by themselves establish clinical response, causal effect, or prediction."
  )
  make_comment_tbl("paired_response_geometry", comments)
}

build_final_paragraph <- function(module_comments) {
  modules <- unique(module_comments$module)
  has_pairs <- "paired_response_geometry" %in% modules
  has_compute <- "compute_clr_aitchison" %in% modules
  has_check <- "check_inputs" %in% modules

  parts <- c()
  if (has_check) {
    parts <- c(parts, "The current run passed through a data-readiness layer that checked sample matching, metadata structure, and pairability.")
  }
  if (has_compute) {
    parts <- c(parts, "Compositional backend tables were produced as the machine-readable truth layer.")
  }
  if (has_pairs) {
    parts <- c(parts, "A paired response summary was available, so the readable layer can describe magnitude and within-group alignment in restrained terms.")
  } else {
    parts <- c(parts, "No paired response module was available here, so interpretation should remain at the readiness or descriptive-structure level.")
  }

  parts <- c(parts, "These notes support descriptive microbiome interpretation only and do not justify responder prediction, clinical recommendation, or other unsupported inference.")
  paste(parts, collapse = " ")
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

  module_comment_tbls <- list(
    build_check_inputs_comments(outdir),
    build_workflow_comments(outdir),
    build_compute_comments(outdir),
    build_geometry_comments(outdir)
  )
  module_comments <- bind_rows(module_comment_tbls)

  if (nrow(module_comments) == 0) {
    stop("No supported backend outputs were found for narrative export in: ", outdir, call. = FALSE)
  }

  write_tsv_safe(module_comments, file.path(outdir, "module_comments.tsv"))

  module_blocks <- lapply(split(module_comments, module_comments$module), function(df) {
    c(
      paste0("## ", df$module[[1]]),
      "",
      paste0("- ", df$comment),
      ""
    )
  })

  final_paragraph <- build_final_paragraph(module_comments)
  md_lines <- c(
    "# Narrative Summary",
    "",
    "This file is the readable layer over the backend TSV outputs. It is intended to behave like a short assistant note, not a manuscript caption and not a clinical report.",
    "",
    unlist(module_blocks, use.names = FALSE),
    "## Compact Summary",
    "",
    final_paragraph,
    ""
  )
  write_text_safe(md_lines, file.path(outdir, "narrative_summary.md"))
}

main()
