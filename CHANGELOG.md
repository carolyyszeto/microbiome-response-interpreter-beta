# Changelog

## v6.5

- Added PowerShell / VS Code one-line smoke-test commands.
- Updated toy workflow documentation to use `--samples_in_rows true`.
- Improved `decision_flow_summary.R` auto-detection for group-level output produced by `paired_response_geometry.R`, including `mean_subject_magnitude` and `mean_cosine`.
- Added reader-facing "How to read the outputs" documentation.
- Added conceptual references for compositional geometry, zero handling, directional statistics, trajectory analysis, PERMANOVA, and PERMDISP.
- No change to core response-geometry calculations.

## 2026-05-20 beta upload polish

- Fixed root README toy quick-start commands to match bundled script options and the five-minute tutorial.
- Updated the five-minute tutorial to remove unadvertised command options and use the documented `--feature_table` / `--outdir` / `--group_geometry` interface.
- Updated `CITATION.cff` with beta title, authors, version, release date, MIT license, repository URL, and related manuscript metadata.
- Added the beta research-preview scope notice at the top of `README.md`.

## v6.4 release-surface QA patch

- Added root `README.md` for public repository orientation.
- Added `LICENSE` using the MIT License template.
- Added `CITATION.cff` draft metadata.
- Added `KNOWN_LIMITATIONS.md` for reviewer- and user-facing scope boundaries.
- Updated `env/environment.yml` and `env/Dockerfile` to include packages used by the R backend, including `readr`, `dplyr`, `tidyr`, and `tibble`.
- Replaced stale `microbiome-response-interpreter-v4` command examples with `microbiome-response-interpreter-v6`.
- Renamed the packaged root folder to `microbiome-response-interpreter-v6`.

## v6.3 release-readiness support

- Added a five-minute toy vignette.
- Added a toy dataset and expected quick-look output notes.
- Added input data structure documentation.
- Added Conda, Docker, and session-info templates.

## v6.2 reader-friendly decision-flow support

- Added a response-organization decision-flow reference.
- Added a script for reader-facing magnitude-coherence summaries.

## v6.1 zero-handling and planning support

- Added targeted pseudocount sensitivity support.
- Added a simulation-based coherence sample-size operating guide.
