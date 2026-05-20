script_file <- normalizePath(
  sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)[1]),
  winslash = "/",
  mustWork = FALSE
)
source(file.path(dirname(script_file), "backend_common.R"))

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
})

usage <- function() {
  cat(
    paste(
      "Usage:",
      "  Rscript skills/microbiome-response-interpreter-v6/scripts/plot_summary.R",
      "    --outdir PATH | --run_dir PATH",
      sep = "\n"
    ),
    "\n"
  )
}

save_plot_if_data <- function(plot_obj, path, width, height) {
  ggsave(path, plot = plot_obj, width = width, height = height, dpi = 180, bg = "white")
  invisible(path)
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

  generated <- list()

  vec_tbl <- read_if_exists(file.path(outdir, "paired_vectors.tsv"))
  if (!is.null(vec_tbl)) {
    subject_levels <- vec_tbl$subject_id[order(vec_tbl$group, vec_tbl$magnitude, vec_tbl$subject_id)] %>%
      unique()
    vec_tbl <- as_tibble(vec_tbl) %>%
      mutate(subject_id = factor(subject_id, levels = subject_levels))

    p_mag <- ggplot(vec_tbl, aes(x = subject_id, y = magnitude, color = group)) +
      geom_point(size = 2, alpha = 0.85) +
      coord_flip() +
      labs(
        title = "Subject-level paired response magnitude",
        x = "Subject",
        y = "Magnitude"
      ) +
      theme_bw(base_size = 11)

    save_plot_if_data(p_mag, file.path(outdir, "magnitude_by_subject.png"), width = 7.5, height = 8.5)
    generated[[length(generated) + 1L]] <- tibble(path = "magnitude_by_subject.png", description = "Subject-level magnitude dot plot")
  }

  group_tbl <- read_if_exists(file.path(outdir, "group_geometry.tsv"))
  if (!is.null(group_tbl)) {
    group_tbl <- as_tibble(group_tbl) %>%
      mutate(group = factor(group, levels = group[order(mean_subject_magnitude)]))

    p_group <- ggplot(group_tbl, aes(x = group, y = mean_subject_magnitude, fill = group)) +
      geom_col(alpha = 0.8, width = 0.7) +
      geom_point(aes(y = mean_vector_magnitude), color = "black", size = 2.2) +
      geom_text(aes(y = mean_subject_magnitude, label = paste0("cos=", fmt_num(mean_cosine, 2))), vjust = -0.6, size = 3) +
      labs(
        title = "Group geometry overview",
        subtitle = "Bars show mean subject magnitude; black points show mean vector magnitude",
        x = "Group",
        y = "Geometry summary"
      ) +
      theme_bw(base_size = 11) +
      theme(legend.position = "none")

    save_plot_if_data(p_group, file.path(outdir, "group_geometry_overview.png"), width = 6.5, height = 4.5)
    generated[[length(generated) + 1L]] <- tibble(path = "group_geometry_overview.png", description = "Group-level geometry summary plot")
  }

  coord_tbl <- read_if_exists(file.path(outdir, "sample_geometry_coords.tsv"))
  if (!is.null(coord_tbl) && all(c("PC1", "PC2") %in% colnames(coord_tbl))) {
    p_struct <- ggplot(as_tibble(coord_tbl), aes(x = PC1, y = PC2)) +
      geom_point(alpha = 0.75, size = 1.8, color = "#2F6B7C") +
      labs(
        title = "Structure overview",
        subtitle = "Simple two-axis view of exported sample geometry coordinates",
        x = "PC1",
        y = "PC2"
      ) +
      theme_bw(base_size = 11)

    save_plot_if_data(p_struct, file.path(outdir, "structure_overview.png"), width = 6, height = 4.8)
    generated[[length(generated) + 1L]] <- tibble(path = "structure_overview.png", description = "Two-axis structure overview scatterplot")
  }

  if (length(generated) > 0) {
    write_tsv_safe(bind_rows(generated), file.path(outdir, "plot_outputs.tsv"))
  } else {
    write_tsv_safe(
      tibble(path = character(), description = character()),
      file.path(outdir, "plot_outputs.tsv")
    )
  }
}

main()
