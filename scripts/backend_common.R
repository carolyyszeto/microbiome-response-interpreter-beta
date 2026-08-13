suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(tibble)
})

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0 || identical(x, "") || all(is.na(x))) y else x
}

parse_cli_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  out <- list()
  i <- 1L
  while (i <= length(args)) {
    token <- args[[i]]
    if (!grepl("^--", token)) {
      stop("Unexpected argument: ", token, call. = FALSE)
    }

    token <- sub("^--", "", token)
    if (grepl("=", token, fixed = TRUE)) {
      parts <- strsplit(token, "=", fixed = TRUE)[[1]]
      key <- parts[[1]]
      value <- paste(parts[-1], collapse = "=")
    } else {
      key <- token
      if (i == length(args) || grepl("^--", args[[i + 1L]])) {
        value <- "TRUE"
      } else {
        value <- args[[i + 1L]]
        i <- i + 1L
      }
    }

    out[[gsub("-", "_", key)]] <- value
    i <- i + 1L
  }
  out
}

require_args <- function(opts, required) {
  missing <- required[vapply(required, function(x) is.null(opts[[x]]) || identical(opts[[x]], ""), logical(1))]
  if (length(missing) > 0) {
    stop("Missing required arguments: ", paste(missing, collapse = ", "), call. = FALSE)
  }
}

as_flag <- function(x, default = FALSE) {
  if (is.null(x) || length(x) == 0 || is.na(x)) {
    return(default)
  }
  tolower(as.character(x)) %in% c("1", "true", "t", "yes", "y")
}

as_number <- function(x, default = NA_real_) {
  if (is.null(x) || length(x) == 0 || identical(x, "")) {
    return(default)
  }
  suppressWarnings(as.numeric(x))
}

get_script_path <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    return(normalizePath(sub("^--file=", "", file_arg[[1]]), winslash = "/", mustWork = FALSE))
  }

  frame_file <- tryCatch(sys.frames()[[1]]$ofile, error = function(...) NULL)
  if (!is.null(frame_file)) {
    return(normalizePath(frame_file, winslash = "/", mustWork = FALSE))
  }

  normalizePath(".", winslash = "/", mustWork = FALSE)
}

get_repo_root <- function() {
  normalizePath(file.path(dirname(get_script_path()), "..", ".."), winslash = "/", mustWork = FALSE)
}

ensure_outdir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  normalizePath(path, winslash = "/", mustWork = FALSE)
}

write_tsv_safe <- function(df, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  readr::write_tsv(df, path)
  invisible(path)
}

write_text_safe <- function(lines, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, con = path, useBytes = TRUE)
  invisible(path)
}

normalize_id <- function(x) {
  x <- as.character(x)
  x <- trimws(x)
  x <- gsub("[\\.-]", "_", x)
  x <- gsub("__+", "_", x)
  tolower(x)
}

as_logical_standard <- function(x) {
  x <- tolower(trimws(as.character(x)))
  x %in% c("true", "t", "1", "yes", "y")
}

derive_before_after <- function(tp_raw = NULL, stage_raw = NULL, sample_clean = NULL) {
  tp_raw <- as.character(tp_raw %||% rep("", length(sample_clean %||% tp_raw %||% stage_raw)))
  stage_raw <- as.character(stage_raw %||% rep("", length(tp_raw)))
  sample_clean <- as.character(sample_clean %||% rep("", length(tp_raw)))

  combined <- tolower(trimws(ifelse(tp_raw == "" | is.na(tp_raw), stage_raw, tp_raw)))
  sample_clean <- tolower(sample_clean)

  out <- rep(NA_character_, length(combined))
  out[grepl("before|pre|baseline|t0|visit\\s*1|v1|^b$|_before", combined)] <- "Before"
  out[grepl("after|post|follow|t1|visit\\s*2|v2|^a$|_after", combined)] <- "After"
  out[is.na(out) & grepl("(_|\\b)1$|(_|\\b)01$", sample_clean)] <- "Before"
  out[is.na(out) & grepl("(_|\\b)2$|(_|\\b)02$", sample_clean)] <- "After"
  out
}

read_data_auto <- function(path) {
  if (!file.exists(path)) {
    stop("Input file does not exist: ", path, call. = FALSE)
  }

  ext <- tolower(tools::file_ext(path))
  if (ext == "rds") {
    return(readRDS(path))
  }
  if (ext == "csv") {
    return(readr::read_csv(path, show_col_types = FALSE))
  }
  if (ext %in% c("tsv", "txt")) {
    return(readr::read_tsv(path, show_col_types = FALSE))
  }

  stop("Unsupported input format for: ", path, call. = FALSE)
}

read_if_exists <- function(path) {
  if (!file.exists(path)) {
    return(NULL)
  }
  read_data_auto(path)
}

coerce_df_to_numeric_matrix <- function(df) {
  if (ncol(df) < 2) {
    stop("Wide matrix input must have at least two columns.", call. = FALSE)
  }

  if (!is.numeric(df[[1]])) {
    row_ids <- as.character(df[[1]])
    num_df <- df[, -1, drop = FALSE]
  } else {
    row_ids <- rownames(df)
    if (is.null(row_ids) || any(row_ids == "")) {
      row_ids <- paste0("row_", seq_len(nrow(df)))
    }
    num_df <- df
  }

  num_df <- as.data.frame(lapply(num_df, function(x) suppressWarnings(as.numeric(x))), check.names = FALSE)
  mat <- as.matrix(num_df)
  rownames(mat) <- row_ids
  storage.mode(mat) <- "numeric"
  mat
}

matrix_from_long <- function(df, sample_col = "SampleID", feature_col = "Feature", value_col = "Value") {
  needed <- c(sample_col, feature_col, value_col)
  if (!all(needed %in% colnames(df))) {
    stop("Long-format input is missing required columns: ", paste(setdiff(needed, colnames(df)), collapse = ", "), call. = FALSE)
  }

  wide <- df %>%
    transmute(
      sample_id = as.character(.data[[sample_col]]),
      feature_id = as.character(.data[[feature_col]]),
      value = as.numeric(.data[[value_col]])
    ) %>%
    group_by(sample_id, feature_id) %>%
    summarise(value = sum(value, na.rm = TRUE), .groups = "drop") %>%
    pivot_wider(names_from = feature_id, values_from = value, values_fill = 0)

  mat <- as.matrix(wide[, -1, drop = FALSE])
  rownames(mat) <- wide$sample_id
  storage.mode(mat) <- "numeric"
  mat
}

guess_samples_in_rows <- function(mat) {
  if (nrow(mat) == 0 || ncol(mat) == 0) {
    return(TRUE)
  }

  row_ids <- normalize_id(rownames(mat) %||% paste0("row_", seq_len(nrow(mat))))
  col_ids <- normalize_id(colnames(mat) %||% paste0("col_", seq_len(ncol(mat))))

  sample_pattern <- "sample|biosample|run|subject|donor|srr|err|drr|dg|sg|dsg"
  feature_pattern <- "asv|otu|genus|species|family|order|class|phylum|tax|feature|k__|p__|c__|o__|f__|g__|s__"

  row_score <- mean(grepl(sample_pattern, row_ids)) - mean(grepl(feature_pattern, row_ids))
  col_score <- mean(grepl(sample_pattern, col_ids)) - mean(grepl(feature_pattern, col_ids))

  if (is.finite(row_score) && is.finite(col_score) && row_score != col_score) {
    return(row_score >= col_score)
  }

  nrow(mat) <= ncol(mat)
}

read_counts_matrix <- function(path,
                               input_format = "auto",
                               sample_col = "SampleID",
                               feature_col = "Feature",
                               value_col = "Value",
                               samples_in_rows = "auto") {
  obj <- read_data_auto(path)

  if (inherits(obj, "matrix")) {
    mat <- obj
  } else if (is.data.frame(obj) || tibble::is_tibble(obj)) {
    if (input_format == "long" || (input_format == "auto" && all(c(sample_col, feature_col, value_col) %in% colnames(obj)))) {
      mat <- matrix_from_long(as.data.frame(obj), sample_col = sample_col, feature_col = feature_col, value_col = value_col)
    } else {
      mat <- coerce_df_to_numeric_matrix(as.data.frame(obj))
    }
  } else {
    stop("Unsupported counts object type: ", paste(class(obj), collapse = ", "), call. = FALSE)
  }

  storage.mode(mat) <- "numeric"
  if (samples_in_rows == "auto") {
    samples_in_rows <- if (guess_samples_in_rows(mat)) "true" else "false"
  }
  if (!as_flag(samples_in_rows, default = TRUE)) {
    mat <- t(mat)
  }

  rownames(mat) <- normalize_id(rownames(mat))
  colnames(mat) <- colnames(mat) %||% paste0("feature_", seq_len(ncol(mat)))
  mat[is.na(mat)] <- 0
  mat[mat < 0] <- 0
  mat
}

find_col <- function(df, requested = "auto", candidates = character()) {
  cols <- colnames(df)
  if (!is.null(requested) && !identical(requested, "") && !identical(requested, "auto")) {
    hit <- cols[tolower(cols) == tolower(requested)]
    if (length(hit) == 0) {
      stop("Requested column not found: ", requested, call. = FALSE)
    }
    return(hit[[1]])
  }

  lower_cols <- tolower(cols)
  for (cand in candidates) {
    hit <- cols[lower_cols == tolower(cand)]
    if (length(hit) > 0) {
      return(hit[[1]])
    }
  }

  NA_character_
}

read_metadata_table <- function(path) {
  obj <- read_data_auto(path)
  df <- as.data.frame(obj, stringsAsFactors = FALSE)
  colnames(df) <- trimws(colnames(df))
  df
}

prepare_metadata <- function(df,
                             sample_col = "auto",
                             subject_col = "auto",
                             group_col = "auto",
                             phase_col = "auto",
                             stage_col = "auto") {
  sample_name <- find_col(df, sample_col, c("SampleID", "Sample_ID", "sample_id", "sampleid", "BioSample", "Run", "run_accession"))
  subject_name <- find_col(df, subject_col, c("subject_id", "Subject_ID", "participant_id", "donor", "host_id", "individual_id"))
  group_name <- find_col(df, group_col, c("group_label", "group", "Group", "arm", "Arm", "treatment", "Treatment"))
  phase_name <- find_col(df, phase_col, c("timepoint_label", "phase", "Phase", "timepoint_ba", "Timepoint_ba", "timepoint", "Timepoint", "visit", "Visit", "tp", "TP"))
  stage_name <- find_col(df, stage_col, c("Stage", "stage", "collection_stage", "collection", "collection_time"))
  baseline_name <- find_col(df, "auto", c("is_baseline", "baseline"))
  post_name <- find_col(df, "auto", c("is_post", "post"))
  order_name <- find_col(df, "auto", c("timepoint_order", "timepoint_rank", "visit_order"))
  intervention_name <- find_col(df, "auto", c("intervention_period_id", "period_id", "intervention_id"))

  if (is.na(sample_name)) {
    stop("Could not identify a sample ID column in metadata.", call. = FALSE)
  }

  sample_raw <- as.character(df[[sample_name]])
  sample_norm <- normalize_id(sample_raw)
  subject_raw <- if (!is.na(subject_name)) as.character(df[[subject_name]]) else rep(NA_character_, nrow(df))
  group_raw <- if (!is.na(group_name)) as.character(df[[group_name]]) else rep(NA_character_, nrow(df))
  phase_raw <- if (!is.na(phase_name)) as.character(df[[phase_name]]) else rep(NA_character_, nrow(df))
  stage_raw <- if (!is.na(stage_name)) as.character(df[[stage_name]]) else rep(NA_character_, nrow(df))
  is_baseline <- if (!is.na(baseline_name)) as_logical_standard(df[[baseline_name]]) else rep(NA, nrow(df))
  is_post <- if (!is.na(post_name)) as_logical_standard(df[[post_name]]) else rep(NA, nrow(df))
  timepoint_order <- if (!is.na(order_name)) suppressWarnings(as.numeric(df[[order_name]])) else rep(NA_real_, nrow(df))
  intervention_period_id <- if (!is.na(intervention_name)) as.character(df[[intervention_name]]) else rep(NA_character_, nrow(df))

  tibble(
    sample_id = sample_raw,
    sample_id_norm = sample_norm,
    subject_id = subject_raw,
    group = group_raw,
    phase_raw = phase_raw,
    stage_raw = stage_raw,
    timepoint_order = timepoint_order,
    is_baseline = is_baseline,
    is_post = is_post,
    intervention_period_id = intervention_period_id,
    phase_std = derive_before_after(phase_raw, stage_raw, sample_norm)
  )
}

select_first_baseline_last_post <- function(row_tbl) {
  if ("include_geometry" %in% colnames(row_tbl)) {
    row_tbl <- row_tbl %>% filter(as_logical_standard(include_geometry))
  }

  grouping_cols <- c("subject_id", "group")
  if ("intervention_period_id" %in% colnames(row_tbl)) {
    grouping_cols <- c(grouping_cols, "intervention_period_id")
  }

  complete_groups <- row_tbl %>%
    filter(
      !is.na(subject_id), subject_id != "",
      !is.na(group), group != "",
      !is.na(sample_id_norm), sample_id_norm != ""
    ) %>%
    group_by(across(all_of(grouping_cols))) %>%
    filter(any(is_baseline %in% TRUE, na.rm = TRUE), any(is_post %in% TRUE, na.rm = TRUE)) %>%
    ungroup()

  if (nrow(complete_groups) == 0) {
    return(tibble())
  }

  baselines <- complete_groups %>%
    filter(is_baseline %in% TRUE) %>%
    mutate(.order = ifelse(is.na(timepoint_order), Inf, timepoint_order)) %>%
    arrange(across(all_of(grouping_cols)), .order, sample_id_norm) %>%
    group_by(across(all_of(grouping_cols))) %>%
    slice(1) %>%
    ungroup() %>%
    select(all_of(grouping_cols), Before = sample_id_norm, baseline_timepoint_order = timepoint_order)

  posts <- complete_groups %>%
    filter(is_post %in% TRUE) %>%
    mutate(.order = ifelse(is.na(timepoint_order), -Inf, timepoint_order)) %>%
    arrange(across(all_of(grouping_cols)), desc(.order), sample_id_norm) %>%
    group_by(across(all_of(grouping_cols))) %>%
    slice(1) %>%
    ungroup() %>%
    select(all_of(grouping_cols), After = sample_id_norm, post_timepoint_order = timepoint_order)

  baselines %>%
    inner_join(posts, by = grouping_cols) %>%
    mutate(pairing_rule = "first_baseline_last_post") %>%
    arrange(subject_id, group, Before, After)
}

build_pairs_from_standardized_rows <- function(df) {
  sample_name <- find_col(df, "auto", c("sample_id", "SampleID", "Sample_ID", "sampleid", "BioSample", "Run", "run_accession"))
  subject_name <- find_col(df, "auto", c("subject_id", "Subject_ID", "participant_id", "donor", "host_id", "individual_id"))
  group_name <- find_col(df, "auto", c("group_label", "group", "Group", "arm", "Arm", "treatment", "Treatment"))
  baseline_name <- find_col(df, "auto", c("is_baseline", "baseline"))
  post_name <- find_col(df, "auto", c("is_post", "post"))
  order_name <- find_col(df, "auto", c("timepoint_order", "timepoint_rank", "visit_order"))
  include_name <- find_col(df, "auto", c("include_geometry"))
  intervention_name <- find_col(df, "auto", c("intervention_period_id", "period_id", "intervention_id"))

  needed <- c(sample_name, subject_name, group_name, baseline_name, post_name)
  if (any(is.na(needed))) {
    return(tibble())
  }

  row_tbl <- tibble(
    sample_id_norm = normalize_id(df[[sample_name]]),
    subject_id = as.character(df[[subject_name]]),
    group = as.character(df[[group_name]]),
    timepoint_order = if (!is.na(order_name)) suppressWarnings(as.numeric(df[[order_name]])) else NA_real_,
    is_baseline = as_logical_standard(df[[baseline_name]]),
    is_post = as_logical_standard(df[[post_name]])
  )

  if (!is.na(include_name)) {
    row_tbl$include_geometry <- df[[include_name]]
  }
  if (!is.na(intervention_name)) {
    row_tbl$intervention_period_id <- as.character(df[[intervention_name]])
  }

  select_first_baseline_last_post(row_tbl)
}

build_pairs_from_wide_pairing_map <- function(df) {
  subject_name <- find_col(df, "auto", c("subject_id", "Subject_ID", "participant_id", "donor", "host_id", "individual_id"))
  group_name <- find_col(df, "auto", c("group_label", "group", "Group", "arm", "Arm", "treatment", "Treatment"))
  baseline_name <- find_col(df, "auto", c("baseline_sample_id", "before_sample_id", "Before"))
  post_name <- find_col(df, "auto", c("post_sample_id", "after_sample_id", "After"))
  intervention_name <- find_col(df, "auto", c("intervention_period_id", "period_id", "intervention_id"))
  rule_name <- find_col(df, "auto", c("pairing_rule"))

  needed <- c(subject_name, group_name, baseline_name, post_name)
  if (any(is.na(needed))) {
    return(tibble())
  }

  out <- tibble(
    subject_id = as.character(df[[subject_name]]),
    group = as.character(df[[group_name]]),
    Before = normalize_id(df[[baseline_name]]),
    After = normalize_id(df[[post_name]]),
    pairing_rule = if (!is.na(rule_name)) as.character(df[[rule_name]]) else "first_baseline_last_post"
  )
  if (!is.na(intervention_name)) {
    out$intervention_period_id <- as.character(df[[intervention_name]])
  }

  out %>%
    filter(!is.na(subject_id), subject_id != "", !is.na(group), group != "", Before != "", After != "") %>%
    arrange(subject_id, group, Before, After)
}

read_pairing_map <- function(path) {
  df <- read_metadata_table(path)
  pairs <- build_pairs_from_wide_pairing_map(df)
  if (nrow(pairs) > 0) {
    return(pairs)
  }
  build_pairs_from_standardized_rows(df)
}

infer_pairs <- function(meta_tbl) {
  has_explicit <- all(c("is_baseline", "is_post") %in% colnames(meta_tbl)) &&
    any(meta_tbl$is_baseline %in% TRUE, na.rm = TRUE) &&
    any(meta_tbl$is_post %in% TRUE, na.rm = TRUE)

  if (has_explicit) {
    pairs <- select_first_baseline_last_post(meta_tbl)
    if (nrow(pairs) > 0) {
      return(pairs)
    }
    return(tibble())
  }

  phase_counts <- meta_tbl %>%
    filter(!is.na(subject_id), !is.na(group), !is.na(phase_std), !is.na(sample_id_norm), sample_id_norm != "") %>%
    group_by(subject_id, group, phase_std) %>%
    summarise(
      sample_id_norm = dplyr::first(sample_id_norm),
      n_samples = dplyr::n(),
      .groups = "drop"
    ) %>%
    pivot_wider(
      names_from = phase_std,
      values_from = c(sample_id_norm, n_samples),
      names_sep = "__"
    )

  if (!all(c("sample_id_norm__Before", "sample_id_norm__After") %in% colnames(phase_counts))) {
    return(tibble())
  }

  phase_counts %>%
    filter(
      !is.na(sample_id_norm__Before),
      !is.na(sample_id_norm__After),
      (n_samples__Before %||% 1) == 1,
      (n_samples__After %||% 1) == 1
    ) %>%
    transmute(
      subject_id = subject_id,
      group = group,
      Before = sample_id_norm__Before,
      After = sample_id_norm__After,
      pairing_rule = "legacy_unambiguous_before_after"
    )
}

dist_from_long <- function(df, sample1_col = "Sample1", sample2_col = "Sample2", value_col = NULL) {
  if (is.null(value_col)) {
    value_col <- setdiff(colnames(df), c(sample1_col, sample2_col))[1]
  }
  ids1 <- normalize_id(df[[sample1_col]])
  ids2 <- normalize_id(df[[sample2_col]])
  vals <- as.numeric(df[[value_col]])

  all_ids <- sort(unique(c(ids1, ids2)))
  mat <- matrix(0, nrow = length(all_ids), ncol = length(all_ids), dimnames = list(all_ids, all_ids))

  for (i in seq_len(nrow(df))) {
    mat[ids1[[i]], ids2[[i]]] <- vals[[i]]
    mat[ids2[[i]], ids1[[i]]] <- vals[[i]]
  }
  as.dist(mat)
}

read_distance_object <- function(path) {
  obj <- read_data_auto(path)
  if (inherits(obj, "dist")) {
    return(obj)
  }
  if (is.matrix(obj)) {
    rownames(obj) <- normalize_id(rownames(obj))
    colnames(obj) <- normalize_id(colnames(obj))
    return(as.dist(obj))
  }
  if (is.data.frame(obj) || tibble::is_tibble(obj)) {
    df <- as.data.frame(obj, stringsAsFactors = FALSE)
    if (all(c("Sample1", "Sample2") %in% colnames(df)) && ncol(df) >= 3) {
      return(dist_from_long(df))
    }
    mat <- coerce_df_to_numeric_matrix(df)
    rownames(mat) <- normalize_id(rownames(mat))
    colnames(mat) <- normalize_id(colnames(mat))
    return(as.dist(mat))
  }
  stop("Unsupported distance object type: ", paste(class(obj), collapse = ", "), call. = FALSE)
}

dist_to_tibble <- function(dist_obj) {
  mat <- as.matrix(dist_obj)
  tibble::rownames_to_column(as.data.frame(mat), "SampleID")
}

cmdscale_tibble <- function(dist_obj, k = 2) {
  ord <- stats::cmdscale(dist_obj, k = k, eig = TRUE)
  coords <- as.data.frame(ord$points)
  colnames(coords) <- paste0("PC", seq_len(ncol(coords)))
  coords <- tibble::rownames_to_column(coords, "SampleID")
  coords$SampleID <- normalize_id(coords$SampleID)
  as_tibble(coords)
}

load_root_functions <- function(files) {
  root <- get_repo_root()
  for (nm in files) {
    source(file.path(root, nm), local = .GlobalEnv)
  }
  invisible(root)
}

summarise_count_matrix <- function(mat) {
  tibble(
    metric = c("n_samples", "n_features", "zero_fraction", "min_library_size", "median_library_size", "max_library_size"),
    value = c(
      nrow(mat),
      ncol(mat),
      mean(mat == 0),
      min(rowSums(mat), na.rm = TRUE),
      stats::median(rowSums(mat), na.rm = TRUE),
      max(rowSums(mat), na.rm = TRUE)
    )
  )
}

fmt_num <- function(x, digits = 2) {
  ifelse(is.na(x), "NA", format(round(as.numeric(x), digits), nsmall = digits, trim = TRUE))
}

fmt_pct <- function(x, digits = 1) {
  ifelse(is.na(x), "NA", paste0(format(round(100 * as.numeric(x), digits), nsmall = digits, trim = TRUE), "%"))
}

clamp_unit <- function(x) {
  pmax(pmin(as.numeric(x), 1), -1)
}

clr_from_counts_pseudocount <- function(count_mat, pseudocount = 0.5) {
  x <- count_mat + pseudocount
  x <- x / rowSums(x)
  lx <- log(x)
  sweep(lx, 1, rowMeans(lx), "-")
}

bayes_multiplicative_replacement <- function(count_mat) {
  d <- ncol(count_mat)
  out <- matrix(0, nrow = nrow(count_mat), ncol = d, dimnames = dimnames(count_mat))

  for (i in seq_len(nrow(count_mat))) {
    x <- as.numeric(count_mat[i, ])
    n <- sum(x)
    if (!is.finite(n) || n <= 0) {
      out[i, ] <- rep(1 / d, d)
      next
    }

    post <- (x + 0.5) / (n + 0.5 * d)
    zero_idx <- x == 0
    z <- sum(zero_idx)

    if (z > 0) {
      nz_min <- min(post[!zero_idx], na.rm = TRUE)
      delta <- min(1 / (d * d), 0.5 * nz_min)
      delta <- max(delta, 1e-12)
      post[zero_idx] <- delta
      scale_nz <- (1 - z * delta) / sum(post[!zero_idx])
      post[!zero_idx] <- post[!zero_idx] * scale_nz
    }

    out[i, ] <- post / sum(post)
  }

  out
}

cmult_repl_or_fallback <- function(count_mat) {
  used_zcompositions <- FALSE
  method_label <- "bayes_multiplicative_fallback"

  if (requireNamespace("zCompositions", quietly = TRUE)) {
    used_zcompositions <- TRUE
    method_label <- "bayes_multiplicative_cmultRepl"
    replaced <- zCompositions::cmultRepl(
      X = count_mat,
      label = 0,
      method = "CZM",
      output = "p-counts"
    )
    replaced <- as.matrix(replaced)
    replaced[replaced <= 0] <- 1e-12
    replaced <- replaced / rowSums(replaced)
  } else {
    replaced <- bayes_multiplicative_replacement(count_mat)
  }

  list(
    composition = replaced,
    used_zcompositions = used_zcompositions,
    method_label = method_label
  )
}

clr_from_composition <- function(comp_mat) {
  lx <- log(comp_mat)
  sweep(lx, 1, rowMeans(lx), "-")
}

aitchison_dist_from_clr <- function(clr_mat) {
  stats::dist(clr_mat, method = "euclidean")
}

compute_clr_and_aitchison <- function(count_mat, method = c("pseudocount", "bayes"), pseudocount = 0.5) {
  method <- match.arg(method)

  if (method == "pseudocount") {
    clr <- clr_from_counts_pseudocount(count_mat, pseudocount = pseudocount)
    used_z <- FALSE
    method_label <- paste0("pseudocount_", pseudocount)
  } else {
    repl <- cmult_repl_or_fallback(count_mat)
    clr <- clr_from_composition(repl$composition)
    used_z <- repl$used_zcompositions
    method_label <- repl$method_label
  }

  dist_obj <- aitchison_dist_from_clr(clr)
  list(
    clr = clr,
    dist = dist_obj,
    used_zcompositions = used_z,
    method_label = method_label
  )
}

observed_richness <- function(count_mat) {
  rowSums(count_mat > 0)
}

cosine_similarity <- function(x, y) {
  nx <- sqrt(sum(x * x))
  ny <- sqrt(sum(y * y))
  if (nx == 0 || ny == 0) {
    return(NA_real_)
  }
  sum(x * y) / (nx * ny)
}

compute_group_cosines <- function(vmat) {
  mu <- colMeans(vmat)
  vapply(seq_len(nrow(vmat)), function(i) cosine_similarity(vmat[i, ], mu), numeric(1))
}

# Participant-excluded directional reference.  This is deliberately separate
# from compute_group_cosines(), which remains the legacy full-sample metric.
compute_loo_cosines <- function(vmat) {
  if (is.null(dim(vmat))) vmat <- matrix(vmat, nrow = 1)
  n <- nrow(vmat)
  vapply(seq_len(n), function(i) {
    if (n < 2) return(NA_real_)
    cosine_similarity(vmat[i, ], colMeans(vmat[-i, , drop = FALSE]))
  }, numeric(1))
}

geometry_directional_summary <- function(vec_df) {
  vec_df %>% group_by(group) %>% group_modify(~{
    vmat <- do.call(rbind, .x$vector)
    mag <- sqrt(rowSums(vmat * vmat))
    tibble(subject_id = .x$subject_id, magnitude = mag,
      loo_reference_cosine = compute_loo_cosines(vmat),
      legacy_full_sample_mean_cosine = compute_group_cosines(vmat))
  }) %>% ungroup()
}

compute_subject_vectors <- function(clr_mat, pairs_df) {
  vectors <- lapply(seq_len(nrow(pairs_df)), function(i) {
    b <- pairs_df$Before[i]
    a <- pairs_df$After[i]
    if (!(b %in% rownames(clr_mat) && a %in% rownames(clr_mat))) {
      return(NULL)
    }
    v <- clr_mat[a, ] - clr_mat[b, ]
    tibble(
      subject_id = pairs_df$subject_id[i],
      group = pairs_df$group[i],
      vector = list(as.numeric(v))
    )
  })
  bind_rows(vectors)
}
