# Changelog V5.2

## Release Purpose

V5.2 promotes the skill to a practical direct-backend release for standardized geometry-ready microbiome dataset bundles while preserving the existing conservative scientific scope.

This remains practical support, not a validated software product, clinical tool, prediction tool, or manuscript computation engine.

## Backend Interface Additions

- Added direct `--pairing_map` support for standardized explicit baseline/post pairing.
- Added `--feature_table` as an alias for `--counts`.
- Added `--run_dir` as an alias for `--outdir` in export/readable/plot scripts.
- `paired_response_geometry.R` can use standardized `pairing_map_baseline_post.tsv` inputs.
- Fallback pairing can use standardized `is_baseline` and `is_post` columns where explicit pair selection is needed.

## Real Backend Evidence

- Palleja 2018 direct backend test: pass; `n_pairs=12`; group label `antibiotic_recovery`.
- David 2014 direct backend test: pass; Animal-only subset; no Plant anchors; no Day 0 anchors; unique paired subjects `10`; geometry rows `112`.

## Scope Boundaries

- Conservative interpretation boundaries are unchanged.
- No clinical, predictive, responder, or individualized recommendation claims are introduced.
- David 2014 Animal-arm-only geometry remains a dense within-subject short-term diet perturbation diagnostic, not fiber replication.
- Wastyk/main manuscript data must not be reused as external portability validation.

## Remaining Caveat

The package is practical microbiome analysis support. It is not a validated software product or a certified analysis engine.
