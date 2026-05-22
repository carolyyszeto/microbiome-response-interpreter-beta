# Backend Scripts

These scripts are the packaged compute layer for `microbiome-response-interpreter-v6.5`.

Within this skill package, `scripts/` is the packaged compute layer used by the skill.

For execution order and wrapper-facing use, start with [../SKILL.md](../SKILL.md) and [../references/backend-modules.md](../references/backend-modules.md).

## Quick-start tutorial and example data

For a five-minute workflow check, use `../tutorials/five-minute-toy-vignette.md` with the bundled artificial dataset in `../examples/toy_dataset/`.

### Windows PowerShell / VS Code terminal toy smoke test

PowerShell does not use Unix backslash line continuations; copy these one-line commands from the repository root:

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

For input formatting rules, see `../references/input-data-structure.md`.

For dependency and environment templates, see `../env/environment.yml`, `../env/Dockerfile`, and `../env/session-info-template.md`.

## Expected Inputs

Supported abundance/count inputs:

- `RDS` count matrices
- wide `csv/tsv` matrices
- long `csv/tsv` tables with explicit sample, feature, and value columns

Supported distance inputs:

- `RDS` `dist` objects
- square distance matrices
- long `Sample1` / `Sample2` / value tables

Supported metadata:

- sample IDs
- subject IDs for paired analysis
- group labels
- timepoint or phase labels that can be mapped to `Before` / `After`

## Shared Modules

These modules provide the core packaged compute behavior:

- `backend_common.R`
- `check_inputs.R`
- `recommend_workflow.R`
- `compute_clr_aitchison.R`
- `paired_response_geometry.R`
- `export_summary.R`

## Package-Local Additions

These files currently exist only in the packaged skill:

- `export_narrative_summary.R`
- `plot_summary.R`
- this `README.md`

The packaged `backend_common.R` also contains extra helpers used by the readability layer, so it is not a byte-identical mirror of the backend reference.

## Scripts

### `backend_common.R`

Shared helpers for CLI parsing, input loading, sample normalization, metadata preparation, pair inference, and manifest-friendly table writing.

### `check_inputs.R`

Validates structure and overlap across counts, metadata, and distance inputs.

Outputs:

- `check_inputs_summary.tsv`
- `check_inputs_messages.tsv`
- `check_inputs_pairs.tsv`

### `recommend_workflow.R`

Writes a recommended backend path from the supplied inputs.

Outputs:

- `workflow_recommendation.tsv`
- `workflow_notes.tsv`

### `compute_clr_aitchison.R`

Computes CLR matrices and Aitchison distances from count inputs.

Outputs:

- `clr_pseudocount.tsv`
- `clr_bayes.tsv`
- `aitchison_pseudocount.tsv`
- `aitchison_bayes.tsv`
- `compute_clr_aitchison_summary.tsv`

### `paired_response_geometry.R`

Computes paired Before/After summaries from exactly one of counts, CLR, or distance input plus metadata.

Outputs:

- `paired_vectors.tsv`
- `group_geometry.tsv`
- `sample_geometry_coords.tsv`
- `pair_mapping.tsv`
- `paired_response_geometry_summary.tsv`

### `export_summary.R`

Collects a machine-readable run summary and manifest.

Outputs:

- `backend_summary.tsv`
- `backend_manifest.tsv`

### `export_narrative_summary.R`

Builds a readable assistant-style note from existing backend TSV outputs.

Outputs:

- `module_comments.tsv`
- `narrative_summary.md`

Expected behavior:

- 3 to 6 short comments per available module
- one compact summary paragraph
- explicit boundary between supported interpretation and unsupported inference

### `plot_summary.R`

Generates lightweight summary PNGs from existing backend outputs.

Example:

```bash
Rscript scripts/plot_summary.R \
  --outdir output/paired_goldtrial
```

Possible outputs:

- `magnitude_by_subject.png`
- `group_geometry_overview.png`
- `structure_overview.png`
- `plot_outputs.tsv`

## Current Limitations

- the scripts expect tabular intermediates rather than full `phyloseq` objects; export `otu_table` and `sample_data` to TSV before using the packaged CLIs
- distance-mode paired geometry is a fallback and uses PCoA coordinates
- the readable layer depends on backend TSVs already being present
- the scripts do not perform prediction, clinical recommendation, outcome modeling, manuscript figure generation, or study-local report generation
- the optional PNGs are simple summary outputs, not manuscript figures

## Role In The Skill

These scripts are not a product-facing application.

The skill should:

- decide whether the data are ready
- choose which script to run
- interpret outputs conservatively

The scripts should:

- perform deterministic compute
- write machine-readable outputs
- optionally add lightweight readable summaries on top of those outputs
- stay within the audited scientific scope

## Wrapper Note

These scripts are file-writing CLIs. Any future MCP, Claude, Gemini, or generic-agent wrapper will need to:

- run the scripts with explicit paths
- collect written artifacts from `--outdir`
- decide whether to return file paths, parsed table content, or both
## V6.1 add-on scripts

- `pseudocount_sensitivity_check.R`: rerun paired response geometry across a pseudocount grid and export subject-level, group-level, and reference-comparison TSV files. Use for targeted zero-handling robustness checks under fixed pairing, endpoints, and feature filters.
- `coherence_power_guide.R`: simulate directional-coherence operating behavior across sample-size and effect-size grids. Use for conservative planning guidance only, not for validated clinical-trial power claims.


## decision_flow_summary.R

Create a reader-friendly decision-flow summary from group-level magnitude and coherence outputs. Use this after paired response geometry exists and the user needs accessible interpretation or biological follow-up suggestions. The output is not a clinical decision tree, responder classifier, or mechanistic validation workflow.

Example:

```bash
Rscript scripts/decision_flow_summary.R \
  --group_geometry outputs/group_geometry.tsv \
  --outdir outputs/decision_flow \
  --coherence_threshold 0.10 \
  --endpoint_note "Baseline 0 to Week 14 16S endpoint"
```

Outputs:

- `decision_flow_summary.tsv`
- `decision_flow_summary.md`
