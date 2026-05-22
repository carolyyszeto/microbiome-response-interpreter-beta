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
      "  Rscript skills/microbiome-response-interpreter-v6.5/scripts/prepare_repeated_metadata.R",
      "    --metadata PATH",
      "    --outdir PATH",
      "    [--output-metadata PATH]",
      "    [--sample-col NAME]",
      "    [--subject-col NAME]",
      "    [--group-col NAME]",
      "    [--phase-col NAME]",
      "    [--stage-col NAME]",
      "    [--order-col NAME]",
      "    [--baseline-indicator-col NAME]",
      "    [--baseline-sample-col NAME]",
      "    [--default-group-label LABEL]",
      sep = "\n"
    ),
    "\n"
  )
}

write_metadata_output <- function(df, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  ext <- tolower(tools::file_ext(path))
  if (ext == "tsv") {
    readr::write_tsv(df, path)
  } else {
    readr::write_csv(df, path)
  }
  invisible(path)
}

trim_na <- function(x) {
  x <- as.character(x)
  x <- trimws(x)
  x[x == ""] <- NA_character_
  x
}

parse_baseline_flag <- function(x) {
  raw <- tolower(trimws(as.character(x)))
  raw[raw %in% c("", "na", "null")] <- NA_character_
  out <- rep(NA, length(raw))
  out[raw %in% c("1", "true", "t", "yes", "y", "baseline", "before", "pre", "reference", "ref")] <- TRUE
  out[raw %in% c("0", "false", "f", "no", "n", "after", "post", "followup", "follow_up", "follow-up")] <- FALSE
  out
}

coerce_order_value <- function(x) {
  raw <- trim_na(x)
  if (all(is.na(raw))) {
    return(rep(NA_real_, length(raw)))
  }

  num <- suppressWarnings(as.numeric(raw))
  if (all(is.na(raw) == is.na(num))) {
    return(num)
  }

  dt <- suppressWarnings(as.POSIXct(raw, tz = "UTC"))
  if (all(is.na(raw) == is.na(dt))) {
    return(as.numeric(dt))
  }

  d <- suppressWarnings(as.Date(raw))
  if (all(is.na(raw) == is.na(d))) {
    return(as.numeric(d))
  }

  rep(NA_real_, length(raw))
}

resolve_group_values <- function(group_raw, default_group_label = NULL) {
  group_clean <- trim_na(group_raw)
  unique_nonmissing <- unique(group_clean[!is.na(group_clean)])

  if (length(unique_nonmissing) == 0) {
    if (is.null(default_group_label) || identical(trimws(default_group_label), "")) {
      stop("No group column values were available and no --default-group-label was supplied.", call. = FALSE)
    }
    return(list(values = rep(default_group_label, length(group_clean)), default_used = TRUE))
  }

  if (any(is.na(group_clean))) {
    if (length(unique_nonmissing) == 1) {
      group_clean[is.na(group_clean)] <- unique_nonmissing[[1]]
    } else {
      stop("Group values are partially missing across multiple groups. Fill them manually or use a single-group subset.", call. = FALSE)
    }
  }

  list(values = group_clean, default_used = FALSE)
}

validate_subject_structure <- function(tbl) {
  subject_counts <- tbl %>%
    count(subject_id, name = "n_rows")

  bad <- subject_counts %>% filter(n_rows != 2)
  if (nrow(bad) > 0) {
    details <- paste0(bad$subject_id, "(", bad$n_rows, ")")
    stop(
      "This helper only supports exact two-row repeated metadata per subject. Problem subjects: ",
      paste(details, collapse = ", "),
      call. = FALSE
    )
  }
}

build_output_tbl <- function(base_tbl, phase, mode_label, source_df) {
  out_core <- base_tbl %>%
    mutate(
      group = as.character(group),
      phase = phase,
      timepoint_rank = ifelse(phase == "Before", 1L, 2L),
      pair_prep_mode = mode_label
    ) %>%
    select(sample_id, subject_id, group, phase, timepoint_rank, pair_prep_mode)

  extra_cols <- source_df[, setdiff(colnames(source_df), colnames(out_core)), drop = FALSE]
  bind_cols(out_core, extra_cols)
}

derive_from_explicit_phase <- function(base_tbl) {
  phase <- derive_before_after(base_tbl$phase_raw, base_tbl$stage_raw, base_tbl$sample_id_norm)
  chk <- base_tbl %>%
    mutate(phase = phase) %>%
    count(subject_id, phase, name = "n_rows") %>%
    tidyr::pivot_wider(names_from = phase, values_from = n_rows, values_fill = 0)

  if (!all(c("Before", "After") %in% colnames(chk))) {
    return(NULL)
  }
  if (all(chk$Before == 1 & chk$After == 1)) {
    return(phase)
  }
  NULL
}

derive_from_baseline_indicator <- function(base_tbl) {
  flag <- parse_baseline_flag(base_tbl$baseline_indicator_raw)
  if (all(is.na(flag))) {
    return(NULL)
  }

  chk <- base_tbl %>%
    mutate(flag = flag) %>%
    group_by(subject_id) %>%
    summarise(
      n_true = sum(flag %in% TRUE, na.rm = TRUE),
      n_false = sum(flag %in% FALSE, na.rm = TRUE),
      n_missing = sum(is.na(flag)),
      .groups = "drop"
    )

  if (all(chk$n_true == 1 & chk$n_false == 1 & chk$n_missing == 0)) {
    return(ifelse(flag, "Before", "After"))
  }
  NULL
}

derive_from_baseline_sample <- function(base_tbl) {
  baseline_sample <- normalize_id(base_tbl$baseline_sample_raw)
  baseline_sample[baseline_sample == ""] <- NA_character_
  if (all(is.na(baseline_sample))) {
    return(NULL)
  }

  chk <- base_tbl %>%
    mutate(
      baseline_sample = baseline_sample,
      is_baseline = sample_id_norm == baseline_sample
    ) %>%
    group_by(subject_id) %>%
    summarise(
      n_baseline_matches = sum(is_baseline, na.rm = TRUE),
      n_unique_reference = n_distinct(baseline_sample[!is.na(baseline_sample)]),
      n_missing = sum(is.na(baseline_sample)),
      .groups = "drop"
    )

  if (all(chk$n_baseline_matches == 1 & chk$n_unique_reference == 1 & chk$n_missing == 0)) {
    return(ifelse(base_tbl$sample_id_norm == baseline_sample, "Before", "After"))
  }
  NULL
}

derive_from_order <- function(base_tbl) {
  order_value <- coerce_order_value(base_tbl$order_raw)
  if (all(is.na(order_value))) {
    return(NULL)
  }

  chk <- base_tbl %>%
    mutate(order_value = order_value) %>%
    group_by(subject_id) %>%
    summarise(
      n_missing = sum(is.na(order_value)),
      n_unique = n_distinct(order_value[!is.na(order_value)]),
      min_value = suppressWarnings(min(order_value, na.rm = TRUE)),
      max_value = suppressWarnings(max(order_value, na.rm = TRUE)),
      .groups = "drop"
    )

  if (!all(chk$n_missing == 0 & chk$n_unique == 2 & chk$min_value < chk$max_value)) {
    return(NULL)
  }

  base_tbl %>%
    mutate(order_value = order_value) %>%
    group_by(subject_id) %>%
    mutate(phase = ifelse(order_value == min(order_value), "Before", "After")) %>%
    ungroup() %>%
    pull(phase)
}

main <- function() {
  opts <- parse_cli_args()
  if (as_flag(opts$help)) {
    usage()
    return(invisible(NULL))
  }

  require_args(opts, c("metadata", "outdir"))
  outdir <- ensure_outdir(opts$outdir)
  output_metadata <- opts$output_metadata %||% file.path(outdir, "prepared_paired_metadata.csv")

  df <- read_metadata_table(opts$metadata)
  sample_name <- find_col(df, opts$sample_col %||% "auto", c("SampleID", "Sample_ID", "sample_id", "sampleid", "BioSample", "Run", "run_accession"))
  subject_name <- find_col(df, opts$subject_col %||% "auto", c("subject_id", "Subject_ID", "participant_id", "donor", "host_id", "individual_id"))
  group_name <- find_col(df, opts$group_col %||% "auto", c("group", "Group", "arm", "Arm", "treatment", "Treatment"))
  phase_name <- find_col(df, opts$phase_col %||% "auto", c("phase", "Phase", "timepoint_ba", "Timepoint_ba", "timepoint", "Timepoint", "visit", "Visit", "tp", "TP"))
  stage_name <- find_col(df, opts$stage_col %||% "auto", c("Stage", "stage", "collection_stage", "collection", "collection_time"))
  order_name <- find_col(df, opts$order_col %||% "auto", c("order", "Order", "time_order", "timepoint_order", "visit_order", "collection_order", "donation_order", "day", "days_from_baseline", "week", "month"))
  baseline_indicator_name <- find_col(df, opts$baseline_indicator_col %||% "auto", c("baseline", "is_baseline", "baseline_indicator", "reference", "is_reference"))
  baseline_sample_name <- find_col(df, opts$baseline_sample_col %||% "auto", c("baseline_sample", "reference_sample", "baseline_id"))

  if (is.na(sample_name)) {
    stop("Could not identify a sample ID column in metadata.", call. = FALSE)
  }
  if (is.na(subject_name)) {
    stop("Could not identify a subject/donor column in metadata.", call. = FALSE)
  }

  sample_id <- trim_na(df[[sample_name]])
  subject_id <- trim_na(df[[subject_name]])
  if (any(is.na(sample_id))) {
    stop("Sample IDs contain missing values. Clean the metadata before pairing.", call. = FALSE)
  }
  if (any(is.na(subject_id))) {
    stop("Subject IDs contain missing values. Clean the metadata before pairing.", call. = FALSE)
  }

  sample_id_norm <- normalize_id(sample_id)
  if (anyDuplicated(sample_id_norm) > 0) {
    dup_ids <- unique(sample_id[duplicated(sample_id_norm)])
    stop("Normalized sample IDs must be unique. Duplicates: ", paste(dup_ids, collapse = ", "), call. = FALSE)
  }

  group_res <- resolve_group_values(
    if (!is.na(group_name)) df[[group_name]] else rep(NA_character_, nrow(df)),
    default_group_label = opts$default_group_label %||% NULL
  )

  base_tbl <- tibble(
    sample_id = sample_id,
    sample_id_norm = sample_id_norm,
    subject_id = subject_id,
    group = group_res$values,
    phase_raw = if (!is.na(phase_name)) trim_na(df[[phase_name]]) else rep(NA_character_, nrow(df)),
    stage_raw = if (!is.na(stage_name)) trim_na(df[[stage_name]]) else rep(NA_character_, nrow(df)),
    order_raw = if (!is.na(order_name)) df[[order_name]] else rep(NA_character_, nrow(df)),
    baseline_indicator_raw = if (!is.na(baseline_indicator_name)) df[[baseline_indicator_name]] else rep(NA_character_, nrow(df)),
    baseline_sample_raw = if (!is.na(baseline_sample_name)) df[[baseline_sample_name]] else rep(NA_character_, nrow(df))
  )

  validate_subject_structure(base_tbl)

  bad_group <- base_tbl %>%
    group_by(subject_id) %>%
    summarise(n_groups = n_distinct(group), .groups = "drop") %>%
    filter(n_groups != 1)
  if (nrow(bad_group) > 0) {
    stop("Each subject must map to exactly one group in the prepared paired metadata.", call. = FALSE)
  }

  phase <- derive_from_explicit_phase(base_tbl)
  mode <- "explicit_phase"
  if (is.null(phase)) {
    phase <- derive_from_baseline_indicator(base_tbl)
    mode <- "baseline_indicator"
  }
  if (is.null(phase)) {
    phase <- derive_from_baseline_sample(base_tbl)
    mode <- "baseline_sample"
  }
  if (is.null(phase)) {
    phase <- derive_from_order(base_tbl)
    mode <- "order_column"
  }
  if (is.null(phase)) {
    stop(
      paste(
        "Could not derive unambiguous Before/After labels.",
        "Supported low-ambiguity cases are exact two-row subjects with explicit phase labels, baseline flags, baseline-sample identifiers, or a parseable order column."
      ),
      call. = FALSE
    )
  }

  prepared_metadata <- build_output_tbl(base_tbl, phase, mode, df) %>%
    arrange(subject_id, timepoint_rank, sample_id)

  summary_tbl <- tibble(
    metric = c(
      "n_input_rows",
      "n_subjects",
      "n_output_rows",
      "n_output_pairs",
      "derivation_mode",
      "default_group_used",
      "output_metadata"
    ),
    value = c(
      nrow(df),
      dplyr::n_distinct(prepared_metadata$subject_id),
      nrow(prepared_metadata),
      nrow(prepared_metadata) / 2,
      mode,
      ifelse(group_res$default_used, "TRUE", "FALSE"),
      normalizePath(output_metadata, winslash = "/", mustWork = FALSE)
    )
  )

  messages_tbl <- tibble(
    level = "info",
    code = c("PREP_MODE", "PAIRING_SCOPE", "GROUP_SOURCE"),
    message = c(
      paste0("Derived paired metadata using ", mode, "."),
      "This helper only supports exact two-row repeated metadata per subject and fails conservatively on ambiguous structures.",
      if (group_res$default_used) {
        paste0("A default group label was applied to all rows: ", opts$default_group_label)
      } else {
        "Existing group values were preserved or completed from a single existing group label."
      }
    )
  )

  write_metadata_output(prepared_metadata, output_metadata)
  write_tsv_safe(summary_tbl, file.path(outdir, "prepare_repeated_metadata_summary.tsv"))
  write_tsv_safe(messages_tbl, file.path(outdir, "prepare_repeated_metadata_messages.tsv"))
}

main()
