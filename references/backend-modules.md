# Backend Modules

## Purpose

This file summarizes how the current packaged skill should use its computational scripts.

Architecture:

- `scripts/` is the packaged computational core used by the skill
- `references/` documents routing and interpretation boundaries
- standardized geometry-ready bundles can run directly when they provide compatible feature tables, metadata, and pairing maps

Do not depend on local development paths outside the packaged skill folder.

The skill should orchestrate these modules, not replace them with freehand recalculation and not present them as an end-user application.

## `scripts/check_inputs.R`

Purpose:

- validate counts, metadata, and optional distance inputs
- normalize sample IDs
- report sample overlap
- detect Before/After pairability

Use when:

- data readiness is uncertain
- paired analysis is being considered
- metadata matching must be checked before routing

Key outputs:

- `check_inputs_summary.tsv`
- `check_inputs_messages.tsv`
- `check_inputs_pairs.tsv`

Current CLI:

- `--feature_table` or `--counts`
- `--metadata`
- `--pairing_map`
- `--outdir`

## `scripts/recommend_workflow.R`

Purpose:

- translate available inputs into a recommended compute path
- keep excluded branches out of scope

Use when:

- the workflow is not obvious after manual inspection
- the user wants practical routing guidance

Key outputs:

- `workflow_recommendation.tsv`
- `workflow_notes.tsv`

Current CLI:

- `--metadata`
- `--pairing_map`
- `--outdir`

## `scripts/compute_clr_aitchison.R`

Purpose:

- compute CLR matrices and Aitchison distances from count inputs
- preserve the source-of-truth pseudocount and Bayesian/multiplicative zero-handling behavior from the audited root modules

Use when:

- counts or count-like taxonomy tables are available
- compositional analysis is appropriate

Key outputs:

- `clr_pseudocount.tsv`
- `clr_bayes.tsv`
- `aitchison_pseudocount.tsv`
- `aitchison_bayes.tsv`
- `compute_clr_aitchison_summary.tsv`

Current CLI:

- `--feature_table` or `--counts`
- `--outdir`

## `scripts/paired_response_geometry.R`

Purpose:

- summarize paired Before/After response geometry
- support either CLR/count mode or distance-based fallback mode
- consume standardized `pairing_map_baseline_post.tsv` files through `--pairing_map`

Use when:

- metadata support true pairing
- the user needs restrained response interpretation

Preferred mode:

- counts or CLR input

Fallback mode:

- precomputed distance object, interpreted through 2D PCoA coordinates

Key outputs:

- `paired_vectors.tsv`
- `group_geometry.tsv`
- `sample_geometry_coords.tsv`
- `pair_mapping.tsv`
- `paired_response_geometry_summary.tsv`

Current CLI:

- `--feature_table` or `--counts`
- `--metadata`
- `--pairing_map`
- `--outdir`

Standardized pairing:

- Prefer explicit `--pairing_map` when the dataset bundle already encodes geometry-ready baseline/post rows.
- Use `is_baseline` and `is_post` flags when standardized row-wise pairing requires deterministic baseline/post selection.

## `scripts/export_summary.R`

Purpose:

- write a machine-readable summary of what ran
- collect a simple output manifest

Use when:

- backend results should be bundled into a stable summary

Key outputs:

- `backend_summary.tsv`
- `backend_manifest.tsv`
- `run_manifest.tsv`

Current CLI:

- `--run_dir` or `--outdir`

## `scripts/export_narrative_summary.R`

Purpose:

- read existing backend TSV outputs
- convert them into short descriptive comments
- write one compact narrative summary

Use when:

- backend truth tables already exist
- the user needs a lighter assistant-style note

Key outputs:

- `module_comments.tsv`
- `narrative_summary.md`

Current CLI:

- `--run_dir` or `--outdir`

## `scripts/plot_summary.R`

Purpose:

- generate lightweight summary plots from existing backend outputs
- improve readability without creating manuscript-style figures

Use when:

- the required backend TSVs are already present
- a quick visual summary would help interpretation

Key outputs may include:

- `magnitude_by_subject.png`
- `group_geometry_overview.png`
- `structure_overview.png`
- `plot_outputs.tsv`

Current CLI:

- `--run_dir` or `--outdir`

## Important Scope Rule

These modules are compute helpers, not interpretation engines. The skill must still decide what language is justified and must keep clinical, predictive, and customer-facing claims out of scope.

These modules also do not make this package a manuscript engine or a cross-domain framework.

## Practical Rule

If the task requires real compute:

- call the backend
- inspect its machine-readable outputs
- translate those outputs into restrained scientific interpretation

If the task is only about readiness, routing, or scope:

- the skill may stop after orchestration without forcing unnecessary compute

If the task needs a lighter human-readable layer after compute:

- keep the TSVs as truth
- run `export_narrative_summary.R`
- optionally run `plot_summary.R`
