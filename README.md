# Microbiome Response Interpreter beta

**Beta research-preview notice:** This is a beta research-preview companion skill for the associated microbiome response-geometry preprint. It is intended for exploratory inspection, demonstration, and reproducibility support only. It is not a clinical, diagnostic, predictive, efficacy, or mechanistic tool.

This repository provides a beta research workflow for applying a microbiome response-geometry framework. It separates paired response magnitude from directional coherence, then helps users summarize robustness, zero-handling sensitivity, sample-size operating context, and reader-facing interpretation flow.

Current packaged version: `v6.5`.

## Status and scope

This is a research-preview implementation intended for reproducibility, teaching, and exploratory application. It is not a validated clinical, diagnostic, predictive, regulatory, or production software tool. It does not replace PERMANOVA, PERMDISP, differential-abundance analysis, longitudinal modelling, or biological validation.

## Quick start with the toy dataset

The toy dataset is intended as a five-minute smoke test. It checks that the input files, paired response-geometry workflow, decision-flow summary, and quick-look outputs can run end to end.

### Windows PowerShell / VS Code terminal

PowerShell does not use Unix backslash (`\`) line continuation. Run these one-line commands one at a time from the repository root.

```powershell
mkdir -Force outputs/toy
Rscript scripts/check_inputs.R --feature_table examples/toy_dataset/feature_table.tsv --metadata examples/toy_dataset/metadata.tsv --pairing_map examples/toy_dataset/pairing_map.tsv --outdir outputs/toy
Rscript scripts/paired_response_geometry.R --feature_table examples/toy_dataset/feature_table.tsv --metadata examples/toy_dataset/metadata.tsv --pairing_map examples/toy_dataset/pairing_map.tsv --outdir outputs/toy --pseudocount 0.5 --samples_in_rows true
Rscript scripts/decision_flow_summary.R --group_geometry outputs/toy/group_geometry.tsv --outdir outputs/toy/decision_flow --endpoint_note "Toy before-after example"
```
Optional quick-look plots:

```powershell
Rscript scripts/plot_summary.R --outdir outputs/toy
```

Optional pseudocount sensitivity smoke test:

```powershell
Rscript scripts/pseudocount_sensitivity_check.R --feature_table examples/toy_dataset/feature_table.tsv --metadata examples/toy_dataset/metadata.tsv --pairing_map examples/toy_dataset/pairing_map.tsv --outdir outputs/toy/pseudocount --pseudocounts 0.5,1.0 --reference_pseudocount 0.5 --samples_in_rows true
```

Optional sample-size operating-guide smoke test:
```powershell
Rscript scripts/coherence_power_guide.R --outdir outputs/toy/power --sample_sizes 8,12 --effect_sizes 0,0.8 --n_features 50 --n_reps 20 --n_perm 99 --seed 123
```

The toy feature table stores samples in rows. The explicit `--samples_in_rows true` flag avoids orientation auto-detection ambiguity in very small toy matrices.

### Linux/macOS/WSL
Use the multiline commands below only in Linux, macOS, WSL, or another shell that supports backslash (\) line continuation. Do not paste these commands into PowerShell.

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

See `tutorials/five-minute-toy-vignette.md` for a step-by-step walkthrough and `examples/toy_dataset/expected_quicklook.md` for the expected output shape.

## Input data

The public interface expects tabular files rather than direct `phyloseq` objects:

- `feature_table.tsv`: a numeric feature table. The workflow supports either samples in rows or samples in columns when the orientation is specified. For the bundled toy dataset, samples are stored in rows, with `sample_id` in the first column and microbial features in the remaining columns. For feature-by-sample tables, provide feature IDs in the first column and sample IDs as the remaining columns, and set the orientation accordingly.
- `metadata.tsv`: one row per sample with sample ID, subject ID, group, and timepoint information.
- `pairing_map.tsv`: one row per paired comparison linking each subject's baseline and follow-up samples.

Do not pre-CLR-transform the feature table before using the bundled scripts. The workflow applies zero handling and CLR transformation internally. See `references/input-data-structure.md` for details.

## Main modules

- `scripts/paired_response_geometry.R`: compute paired response magnitude and directional coherence summaries.
- `scripts/pseudocount_sensitivity_check.R`: compare qualitative calls across user-specified pseudocount settings.
- `scripts/coherence_power_guide.R`: run a simulation-based operating guide for sample-size and effect-size planning.
- `scripts/decision_flow_summary.R`: translate magnitude-coherence summaries into a cautious interpretation guide.
- `scripts/plot_summary.R`: create quick-look summary plots.

## How to read the outputs

The bundled scripts write plain TSV, Markdown, and PNG files so readers can inspect each step without using a custom viewer. Treat the toy outputs as a workflow demonstration, not as biological evidence.

### Input checks

- `check_inputs_messages.tsv`: human-readable warnings, errors, or notes from input validation.
- `check_inputs_pairs.tsv`: the paired baseline/follow-up sample links that the workflow can use after checking the feature table, metadata, and pairing map.
- `check_inputs_summary.tsv`: a compact audit summary for input dimensions, sample overlap, pairability, and readiness signals.

### Paired response geometry

- `group_geometry.tsv`: group-level response-geometry summary. Key columns are:
  - `group`: intervention or comparison group label.
  - `n_subjects`: number of valid paired participants.
  - `mean_subject_magnitude`: average participant-level baseline-to-follow-up movement size.
  - `mean_vector_magnitude`: magnitude of the group mean response vector.
  - `mean_cosine`: directional coherence, interpreted as average alignment to the group response direction.
- `paired_vectors.tsv`: subject-level paired response-vector summaries. This file is useful for checking heterogeneity, subgroup patterns, and high-influence participants.
- `pair_mapping.tsv`: the final baseline/follow-up sample pairs used for the paired geometry run.
- `sample_geometry_coords.tsv`: quick-look coordinate export for plotting and inspection. Do not interpret it as a full ordination analysis unless the upstream method and coordinate construction are explicitly documented.

### Decision-flow summary

- `decision_flow/decision_flow_summary.md`: reader-facing Markdown summary that translates magnitude-coherence patterns into cautious interpretation categories. It is an interpretation guide, not a clinical decision tree, responder classifier, or mechanism validator.
- `decision_flow/decision_flow_summary.tsv`: machine-readable version of the same decision-flow categories, thresholds, practical interpretation text, and suggested next checks.

### Pseudocount sensitivity

- `pseudocount/pseudocount_sensitivity_comparison.tsv`: comparison against the reference pseudocount, including changes in group-level magnitude and coherence.
- `pseudocount/pseudocount_sensitivity_group.tsv`: group-level geometry summaries for each tested pseudocount.
- `pseudocount/pseudocount_sensitivity_subject.tsv`: subject-level magnitude and alignment summaries for each tested pseudocount.

These outputs compare qualitative calls across pseudocount settings. A stable qualitative call across `0.5` and `1.0` reduces concern about a single pseudocount choice, but it does not prove pseudocount invariance or replace systematic zero-handling benchmarking.

### Planning guide

- `power/coherence_power_guide_summary.tsv`: simulation-based operating guide for planning directional-coherence studies.

This output is not a formal clinical-trial power calculator, minimum detectable effect estimator, or validated sample-size calculator. Toy smoke-test settings with small `n_reps` and `n_perm` are only for checking that the script runs.

### Quick-look plots

`plot_summary.R` may generate simple PNG files such as:

- `magnitude_by_subject.png`: subject-level magnitude plot.
- `group_geometry_overview.png`: group-level magnitude and coherence overview.
- `structure_overview.png`: quick-look coordinate scatterplot from `sample_geometry_coords.tsv`.

These PNGs are inspection aids, not manuscript-ready figures or statistical tests.

## Interpretation patterns

| Pattern | Reader-facing interpretation |
| --- | --- |
| low magnitude + low coherence | Little detectable group-level remodeling; check sample size, endpoint, feature space, and preprocessing. |
| high magnitude + low coherence | Large but heterogeneous movement; inspect individual trajectories, subgroups, baseline dependence, and outliers. |
| low magnitude + higher coherence | Magnitude-limited but organized movement; verify robustness to zero handling, endpoint choice, and feature-space definition. |
| high magnitude + higher coherence | Candidate coordinated response organization; still requires robustness checks and biological/functional follow-up. |

## Conceptual references

- Aitchison J, Greenacre M. Biplots of compositional data. Journal of the Royal Statistical Society Series C. 2002;51:375-392. doi:10.1111/1467-9876.00275.
- Gloor GB, Macklaim JM, Pawlowsky-Glahn V, Egozcue JJ. Microbiome datasets are compositional: and this is not optional. Frontiers in Microbiology. 2017;8:2224. doi:10.3389/fmicb.2017.02224.
- Martin-Fernandez JA, Hron K, Templ M, Filzmoser P, Palarea-Albaladejo J. Bayesian-multiplicative treatment of count zeros in compositional data sets. Statistical Modelling. 2015;15:134-158. doi:10.1177/1471082X14535524.
- Palarea-Albaladejo J, Martin-Fernandez JA. zCompositions: R package for multivariate imputation of left-censored data under a compositional approach. Chemometrics and Intelligent Laboratory Systems. 2015;143:85-96. doi:10.1016/j.chemolab.2015.02.019.
- Mardia KV, Jupp PE. Directional Statistics. Wiley. 2000. doi:10.1002/9780470316979.
- De Caceres M, Coll L, Legendre P, Allen RB, Wiser SK, Fortin MJ, Condit R, Hubbell S. Trajectory analysis in community ecology. Ecological Monographs. 2019;89:e01350. doi:10.1002/ecm.1350.
- Anderson MJ. A new method for non-parametric multivariate analysis of variance. Austral Ecology. 2001;26:32-46. doi:10.1111/j.1442-9993.2001.01070.pp.x.
- Anderson MJ. Distance-based tests for homogeneity of multivariate dispersions. Biometrics. 2006;62:245-253. doi:10.1111/j.1541-0420.2005.00440.x.

## Installation options

Conda-style setup is documented in `env/environment.yml`. A Docker template is provided in `env/Dockerfile`. The scripts primarily require R 4.4.x and common tidyverse packages used by the backend. Optional microbiome packages such as `phyloseq`, `dada2`, and `zCompositions` are included for upstream compatibility and sensitivity workflows, but the core public interface uses tabular files.

## Using this repository with agents

This repository can be used in three agent-assisted modes: OpenAI / ChatGPT skill-style workflows, Claude / Claude Code workflows, and Gemini / Google AI Studio or Vertex AI workflows. The shared rule across all agents is to treat this repository as a **beta research-preview companion workflow**, not as a validated clinical, diagnostic, predictive, efficacy, regulatory, production, or mechanistic tool.

For detailed cross-agent setup instructions, see:

```text
agent_README.md
```

Recommended agent workflow:

1. Read `README.md`, `SKILL.md`, `KNOWN_LIMITATIONS.md`, and `agent_README.md` before running analyses.
2. Run the five-minute toy vignette first to verify the environment and output shape.
3. Inspect user-provided `feature_table.tsv`, `metadata.tsv`, and `pairing_map.tsv` for compatibility before analysis.
4. Run only the documented script interfaces. Do not invent command-line options or infer missing pairings.
5. Summarize response magnitude, directional coherence, pseudocount sensitivity where requested, and claim boundaries.
6. Report missing inputs, incompatible metadata, script failures, or uncertainty directly rather than filling gaps by assumption.

Example agent prompt:

```text
Use this repository as a beta research-preview companion workflow for microbiome response-geometry interpretation. First read README.md, SKILL.md, KNOWN_LIMITATIONS.md, and agent_README.md. Then run the five-minute toy vignette to verify the environment. After that, inspect my feature table, metadata, and pairing map for compatibility. If the inputs are sufficient, run the documented paired response-geometry workflow and summarize response magnitude, directional coherence, pseudocount sensitivity if requested, and claim boundaries. Keep the interpretation exploratory and do not make clinical, predictive, efficacy, diagnostic, regulatory, or mechanistic claims.
```

Agent-specific notes:

- OpenAI / ChatGPT skill-style use: read `SKILL.md` first and use `agents/openai.yaml` as the OpenAI-facing metadata reference.
- Claude / Claude Code use: read `agents/claude.md` as the Claude-specific task guide. In Claude.ai, use it as a sequential instruction reference if parallel subagents are unavailable.
- Gemini use: wrap the documented backend scripts through function calling or a local Python wrapper. Keep API keys outside the repository and never commit credentials.

Agent-use limitations:

- Agents should not treat this repository as a validated software package.
- Agents should not alter the claim boundaries in `README.md`, `SKILL.md`, `KNOWN_LIMITATIONS.md`, or `agent_README.md`.
- Agents should not redistribute raw public datasets, manuscript drafts, reviewer notes, or local working files.
- Agents should not return invented numerical results if script execution fails.


## Claim boundaries

Use this workflow to describe response organization within a specified feature space and endpoint definition. Do not use it to claim clinical efficacy, mechanism, enzyme activity, pathway flux, participant classification, universal method superiority, or pseudocount invariance. The sample-size module is a simulation-based operating guide, not a validated formal power calculator.

## Citation

If using this repository before journal publication, cite the accompanying preprint and the archived software release if available.Preprint:
Szeto CYY, Kwan HS. A response-geometry framework separates microbiome movement magnitude from directional coherence in intervention studies. bioRxiv. 2026. https://doi.org/10.64898/2026.05.22.726133
After publication, update the citation to the journal article and the final archived release. A draft citation metadata file is provided in `CITATION.cff`.

## License

This repository is released under the MIT License. See `LICENSE`.
