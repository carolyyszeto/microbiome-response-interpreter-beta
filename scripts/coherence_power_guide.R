script_file <- normalizePath(
  sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)[1]),
  winslash = "/",
  mustWork = FALSE
)
source(file.path(dirname(script_file), "backend_common.R"))

usage <- function() {
  cat(paste(
    "Usage:",
    "  Rscript scripts/coherence_power_guide.R",
    "    --outdir PATH",
    "    [--sample_sizes 10,15,20,30,40,60]",
    "    [--effect_sizes 0,0.35,0.8,1.4]",
    "    [--n_features 500]",
    "    [--noise_sd 1]",
    "    [--n_reps 500]",
    "    [--n_perm 499]",
    "    [--alpha 0.05]",
    "    [--seed 123]",
    sep = "\n"), "\n")
}

parse_int_grid <- function(x, default) {
  if (is.null(x) || identical(x, "")) return(default)
  vals <- suppressWarnings(as.integer(strsplit(as.character(x), ",", fixed = TRUE)[[1]]))
  vals <- vals[is.finite(vals) & vals > 1]
  if (length(vals) == 0) stop("No valid sample sizes were supplied.", call. = FALSE)
  unique(vals)
}

parse_num_grid <- function(x, default) {
  if (is.null(x) || identical(x, "")) return(default)
  vals <- suppressWarnings(as.numeric(strsplit(as.character(x), ",", fixed = TRUE)[[1]]))
  vals <- vals[is.finite(vals)]
  if (length(vals) == 0) stop("No valid numeric grid values were supplied.", call. = FALSE)
  unique(vals)
}

center_rows <- function(mat) sweep(mat, 1, rowMeans(mat), "-")

coherence_stat <- function(vmat) {
  mu <- colMeans(vmat)
  mean(vapply(seq_len(nrow(vmat)), function(i) cosine_similarity(vmat[i, ], mu), numeric(1)), na.rm = TRUE)
}

signflip_pvalue <- function(vmat, n_perm = 499) {
  obs <- coherence_stat(vmat)
  null_stats <- replicate(n_perm, {
    signs <- sample(c(-1, 1), nrow(vmat), replace = TRUE)
    coherence_stat(vmat * signs)
  })
  p <- (sum(null_stats >= obs, na.rm = TRUE) + 1) / (sum(is.finite(null_stats)) + 1)
  c(observed = obs, null_mean = mean(null_stats, na.rm = TRUE), gap = obs - mean(null_stats, na.rm = TRUE), p_value = p)
}

simulate_vectors <- function(n_subjects, n_features, effect_size, noise_sd) {
  direction <- stats::rnorm(n_features)
  direction <- direction - mean(direction)
  direction <- direction / sqrt(sum(direction * direction))
  noise <- matrix(stats::rnorm(n_subjects * n_features, mean = 0, sd = noise_sd), nrow = n_subjects)
  noise <- center_rows(noise)
  shared <- matrix(effect_size * direction, nrow = n_subjects, ncol = n_features, byrow = TRUE)
  center_rows(shared + noise)
}

main <- function() {
  opts <- parse_cli_args()
  if (as_flag(opts$help)) {
    usage()
    return(invisible(NULL))
  }
  require_args(opts, c("outdir"))
  outdir <- ensure_outdir(opts$outdir)

  sample_sizes <- parse_int_grid(opts$sample_sizes, c(10L, 15L, 20L, 30L, 40L, 60L))
  effect_sizes <- parse_num_grid(opts$effect_sizes, c(0, 0.35, 0.8, 1.4))
  n_features <- as.integer(as_number(opts$n_features, default = 500))
  noise_sd <- as_number(opts$noise_sd, default = 1)
  n_reps <- as.integer(as_number(opts$n_reps, default = 500))
  n_perm <- as.integer(as_number(opts$n_perm, default = 499))
  alpha <- as_number(opts$alpha, default = 0.05)
  seed <- as.integer(as_number(opts$seed, default = 123))
  set.seed(seed)

  grid <- expand.grid(n_subjects = sample_sizes, effect_size = effect_sizes, KEEP.OUT.ATTRS = FALSE)
  rows <- vector("list", nrow(grid))

  for (g in seq_len(nrow(grid))) {
    n <- grid$n_subjects[g]
    es <- grid$effect_size[g]
    rep_stats <- replicate(n_reps, {
      vmat <- simulate_vectors(n, n_features, es, noise_sd)
      signflip_pvalue(vmat, n_perm = n_perm)
    })
    rep_df <- as.data.frame(t(rep_stats))
    rows[[g]] <- tibble(
      n_subjects = n,
      effect_size = es,
      n_features = n_features,
      noise_sd = noise_sd,
      n_reps = n_reps,
      n_perm = n_perm,
      alpha = alpha,
      detection_rate = mean(rep_df$p_value <= alpha, na.rm = TRUE),
      median_observed_coherence = stats::median(rep_df$observed, na.rm = TRUE),
      median_null_mean = stats::median(rep_df$null_mean, na.rm = TRUE),
      median_observed_minus_null_gap = stats::median(rep_df$gap, na.rm = TRUE),
      p10_gap = stats::quantile(rep_df$gap, 0.10, na.rm = TRUE),
      p90_gap = stats::quantile(rep_df$gap, 0.90, na.rm = TRUE)
    )
  }

  summary_tbl <- bind_rows(rows)
  write_tsv_safe(summary_tbl, file.path(outdir, "coherence_power_guide_summary.tsv"))

  note <- c(
    "# Coherence power guide note",
    "",
    paste0("Seed: ", seed),
    paste0("Sample-size grid: ", paste(sample_sizes, collapse = ", ")),
    paste0("Effect-size grid: ", paste(effect_sizes, collapse = ", ")),
    paste0("Feature count: ", n_features),
    paste0("Noise SD: ", noise_sd),
    paste0("Replicates per setting: ", n_reps),
    paste0("Sign-flip permutations per replicate: ", n_perm),
    paste0("Alpha: ", alpha),
    "",
    "Interpretation boundary: this is a simulation-based operating-context screen for study planning. It is not a validated clinical-trial power calculator, a universal minimum detectable effect, or evidence that any empirical cohort should be interpreted as positive or negative."
  )
  write_text_safe(note, file.path(outdir, "coherence_power_guide_note.md"))
}

main()
