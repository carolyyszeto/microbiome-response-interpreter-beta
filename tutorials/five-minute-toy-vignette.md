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

### Windows PowerShell / VS Code terminal

PowerShell does not use Unix backslash line continuations; copy these one-line commands:

```powershell
mkdir -Force outputs/toy
Rscript scripts/check_inputs.R --feature_table examples/toy_dataset/feature_table.tsv --metadata examples/toy_dataset/metadata.tsv --pairing_map examples/toy_dataset/pairing_map.tsv --outdir outputs/toy
Rscript scripts/paired_response_geometry.R --feature_table examples/toy_dataset/feature_table.tsv --metadata examples/toy_dataset/metadata.tsv --pairing_map examples/toy_dataset/pairing_map.tsv --outdir outputs/toy --pseudocount 0.5 --samples_in_rows true
Rscript scripts/decision_flow_summary.R --group_geometry outputs/toy/group_geometry.tsv --outdir outputs/toy/decision_flow --endpoint_note "Toy before-after example"
```

Optional modules:

```powershell
Rscript scripts/pseudocount_sensitivity_check.R --feature_table examples/toy_dataset/feature_table.tsv --metadata examples/toy_dataset/metadata.tsv --pairing_map examples/toy_dataset/pairing_map.tsv --outdir outputs/toy/pseudocount --pseudocounts 0.5,1.0 --reference_pseudocount 0.5 --samples_in_rows true
Rscript scripts/coherence_power_guide.R --outdir outputs/toy/power --sample_sizes 8,12 --effect_sizes 0,0.8 --n_features 50 --n_reps 20 --n_perm 99 --seed 123
Rscript scripts/plot_summary.R --outdir outputs/toy
```

The toy feature table stores samples in rows. The explicit `--samples_in_rows true` flag avoids orientation auto-detection ambiguity in very small toy matrices.

### Linux/macOS/WSL

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
  --pseudocount 0.5 \
  --samples_in_rows true

Rscript scripts/decision_flow_summary.R \
  --group_geometry outputs/toy/group_geometry.tsv \
  --outdir outputs/toy/decision_flow \
  --endpoint_note "Toy before-after example"
```

Optional targeted pseudocount check:

```bash
Rscript scripts/pseudocount_sensitivity_check.R \
  --feature_table examples/toy_dataset/feature_table.tsv \
  --metadata examples/toy_dataset/metadata.tsv \
  --pairing_map examples/toy_dataset/pairing_map.tsv \
  --outdir outputs/toy/pseudocount \
  --pseudocounts 0.5,1.0 \
  --reference_pseudocount 0.5 \
  --samples_in_rows true
```

Optional sample-size operating guide and quick-look plots:

```bash
Rscript scripts/coherence_power_guide.R \
  --outdir outputs/toy/power \
  --sample_sizes 8,12 \
  --effect_sizes 0,0.8 \
  --n_features 50 \
  --n_reps 20 \
  --n_perm 99 \
  --seed 123

Rscript scripts/plot_summary.R \
  --outdir outputs/toy
```

## Expected outputs

Core outputs include:

- `outputs/toy/group_geometry.tsv`
- `outputs/toy/paired_vectors.tsv`
- `outputs/toy/paired_response_geometry_summary.tsv`
- `outputs/toy/decision_flow/decision_flow_summary.md`
- `outputs/toy/pseudocount/`
- `outputs/toy/power/`

## How to read the result

Use this vignette to check that the data load, pairings match, and outputs are produced. Do not use the toy results as biological evidence. The toy dataset is artificial and is only designed to illustrate output shape and interpretation language.

For a full reader-facing guide to each TSV, Markdown, and PNG output, see the root `README.md` section "How to read the outputs."

At a high level:

- `check_inputs_*.tsv` files show whether the toy feature table, metadata, and pairing map align.
- `group_geometry.tsv` summarizes group-level movement size and directional coherence.
- `paired_vectors.tsv` stores subject-level paired response summaries for heterogeneity checks.
- `decision_flow/decision_flow_summary.md` translates magnitude-coherence patterns into cautious interpretation categories; it is not a clinical decision tree, responder classifier, or mechanism validator.
- `pseudocount/` outputs compare qualitative calls across pseudocount settings; stability across `0.5` and `1.0` reduces concern about one pseudocount choice but does not prove pseudocount invariance.
- `power/coherence_power_guide_summary.tsv` is a simulation-based operating guide for planning, not a formal clinical-trial power or sample-size calculator.
- quick-look PNG files from `plot_summary.R` are inspection aids, not manuscript-ready figures.
