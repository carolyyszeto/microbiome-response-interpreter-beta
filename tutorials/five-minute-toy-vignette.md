# Five-Minute Toy Vignette

This tutorial is for a quick installation and workflow check. It is intentionally small enough to run quickly and produce outputs similar in shape to the manuscript-style response-geometry summaries.

## Goal

Run a tiny before/after microbiome feature table through the conservative response-geometry workflow, then export a reader-friendly decision-flow summary.

## Files

Use the toy dataset bundled with the skill:

- `examples/toy_dataset/feature_table.tsv`
- `examples/toy_dataset/metadata.tsv`
- `examples/toy_dataset/pairing_map.tsv`

## Commands

Run from the root of the unpacked skill directory.

```bash
mkdir -p outputs/toy

Rscript scripts/check_inputs.R \
  --feature_table examples/toy_dataset/feature_table.tsv \
  --metadata examples/toy_dataset/metadata.tsv \
  --pairing_map examples/toy_dataset/pairing_map.tsv \
  --outdir outputs/toy

Rscript scripts/paired_response_geometry.R \
  --feature_table examples/toy_dataset/feature_table.tsv \
  --metadata examples/toy_dataset/metadata.tsv \
  --pairing_map examples/toy_dataset/pairing_map.tsv \
  --outdir outputs/toy \
  --pseudocount 0.5

Rscript scripts/decision_flow_summary.R \
  --group_geometry outputs/toy/group_geometry.tsv \
  --outdir outputs/toy/decision_flow \
  --endpoint_note "Toy before-after endpoint"
```

Optional targeted pseudocount check:

```bash
Rscript scripts/pseudocount_sensitivity_check.R \
  --feature_table examples/toy_dataset/feature_table.tsv \
  --metadata examples/toy_dataset/metadata.tsv \
  --pairing_map examples/toy_dataset/pairing_map.tsv \
  --outdir outputs/toy/pseudocount_sensitivity \
  --pseudocounts 0.5,1.0
```

## Expected outputs

Core outputs include:

- `outputs/toy/group_geometry.tsv`
- `outputs/toy/paired_vectors.tsv`
- `outputs/toy/paired_response_geometry_summary.tsv`
- `outputs/toy/decision_flow/decision_flow_summary.md`

## How to read the result

Use this vignette to check that the data load, pairings match, and outputs are produced. Do not use the toy results as biological evidence. The toy dataset is artificial and is only designed to illustrate output shape and interpretation language.
