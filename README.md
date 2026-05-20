# Microbiome Response Interpreter beta

**Beta research-preview notice:** This is a beta research-preview companion skill for the associated microbiome response-geometry preprint. It is intended for exploratory inspection, demonstration, and reproducibility support only. It is not a clinical, diagnostic, predictive, efficacy, or mechanistic tool.

This repository provides a beta research workflow for applying a microbiome response-geometry framework. It separates paired response magnitude from directional coherence, then helps users summarize robustness, zero-handling sensitivity, sample-size operating context, and reader-facing interpretation flow.

## Status and scope

This is a research-preview implementation intended for reproducibility, teaching, and exploratory application. It is not a validated clinical, diagnostic, predictive, regulatory, or production software tool. It does not replace PERMANOVA, PERMDISP, differential-abundance analysis, longitudinal modelling, or biological validation.

## Quick start with the toy dataset

From the repository root, run the five-minute example:

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

See `tutorials/five-minute-toy-vignette.md` for a step-by-step walkthrough and `examples/toy_dataset/expected_quicklook.md` for the expected output shape.

## Input data

The public interface expects tabular files rather than direct `phyloseq` objects:

- `feature_table.tsv`: features by samples, with feature IDs in the first column and sample IDs as remaining columns.
- `metadata.tsv`: one row per sample with sample ID, subject ID, group, and timepoint information.
- `pairing_map.tsv`: one row per paired comparison linking each subject's baseline and follow-up samples.

Do not pre-CLR-transform the feature table before using the bundled scripts. The workflow applies zero handling and CLR transformation internally. See `references/input-data-structure.md` for details.

## Main modules

- `scripts/paired_response_geometry.R`: compute paired response magnitude and directional coherence summaries.
- `scripts/pseudocount_sensitivity_check.R`: compare qualitative calls across user-specified pseudocount settings.
- `scripts/coherence_power_guide.R`: run a simulation-based operating guide for sample-size and effect-size planning.
- `scripts/decision_flow_summary.R`: translate magnitude-coherence summaries into a cautious interpretation guide.
- `scripts/plot_summary.R`: create quick-look summary plots.

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

If using this repository before journal publication, cite the accompanying preprint and the archived software release if available. After publication, update the citation to the journal article and the final archived release. A draft citation metadata file is provided in `CITATION.cff`.

## License

This repository is released under the MIT License. See `LICENSE`.
