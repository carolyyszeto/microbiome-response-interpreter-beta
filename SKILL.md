---
name: microbiome-response-interpreter-v6
description: use when the user has practical microbiome taxonomy or abundance tables plus metadata, including standardized geometry-ready dataset bundles, and needs conservative data-readiness routing, backend execution, targeted pseudocount sensitivity checks, simulation-based sample-size operating guidance, reader-friendly decision-flow summaries, release-readiness tutorials, toy datasets, input-schema guidance, environment templates, and restrained response-geometry summaries. this skill is a microbiome-first practical v6 support package. it is not the manuscript computation engine, not a validated software product, not a predictive or clinical tool, and not a finished cross-platform or multi-domain framework.
---

# Microbiome Response Interpreter

Use this skill when the starting point is practical microbiome analysis support from:

- a taxonomy or abundance table
- a metadata table

This skill is an orchestration-and-interpretation layer over a computational core. It should determine what the dataset can support, recommend the safest mathematical workflow, call the backend when appropriate, and keep the interpretation conservative.

## Release State

- Current packaged identity: `microbiome-response-interpreter-v6`
- Purpose of v6: direct backend execution on standardized geometry-ready dataset bundles, with `--pairing_map`, `--feature_table`, and `--run_dir` support plus V10 David/Palleja implementation stress-test and Palleja pathway-geometry documentation.
- V6.1 add-on: targeted pseudocount sensitivity checks and simulation-based sample-size operating guidance for directional coherence. See [references/changelog-v6-1.md](references/changelog-v6-1.md).
- V6.2 add-on: reader-friendly decision-flow summaries for magnitude/coherence interpretation and biological follow-up planning. See [references/changelog-v6-2.md](references/changelog-v6-2.md).
- V6.3 add-on: release-readiness support with a five-minute toy vignette, toy dataset, input data-structure guide, and Conda/Docker environment templates. See [references/changelog-v6-3.md](references/changelog-v6-3.md).
- V6.4 QA patch: public release-surface materials, aligned dependency files, root README, MIT license, citation metadata, known limitations, and stale command cleanup. See [CHANGELOG.md](CHANGELOG.md).
- For legacy naming transition details, see [references/changelog-v3.md](references/changelog-v3.md)
- For v5.2 release details, see [references/changelog-v5-2.md](references/changelog-v5-2.md)
- For v6 release details, see [references/changelog-v6.md](references/changelog-v6.md)
- For trial-run and claim-boundary guidance, see [references/trial-run-guidance.md](references/trial-run-guidance.md) and [references/claim-boundaries.md](references/claim-boundaries.md)
- For route examples, see [references/route-examples.md](references/route-examples.md)
- For pseudocount sensitivity and sample-size planning guidance, see [references/zero-handling-and-power.md](references/zero-handling-and-power.md)
- For reader-friendly decision-flow guidance, see [references/decision-flow.md](references/decision-flow.md)
- For input data structure, toy tutorial, and environment guidance, see [references/input-data-structure.md](references/input-data-structure.md), [tutorials/five-minute-toy-vignette.md](tutorials/five-minute-toy-vignette.md), and [env/session-info-template.md](env/session-info-template.md)

## Positioning

Treat this package as a practical microbiome-focused support skill.

- It is not the manuscript computation engine.
- It is not a validated software product.
- It is not a predictive, diagnostic, or clinical recommendation tool.
- It supports conservative workflow routing, backend execution, and short summary generation.
- Portability to Claude, Gemini, or generic-agent workflows is future wrapper work, not completed native support.
- Cross-domain extension is future adapter-based scope, not current direct support.

## Readable Output Layer

The package includes a readable reporting layer on top of the backend outputs.

Treat outputs in three layers:

1. TSV backend truth
2. short readable comments and one compact narrative summary
3. optional lightweight summary figures

The readable layer should behave like a short assistant note. It must not turn into a manuscript-caption layer, a customer-facing product layer, or a clinical report.

## Use This Skill For

- readiness checks for taxonomy table + metadata inputs
- paired compositional response analysis when Before/After linkage exists
- targeted pseudocount sensitivity checks for CLR/Aitchison paired-response outputs
- simulation-based sample-size operating guidance for directional coherence under stated assumptions
- reader-friendly decision-flow summaries for high/low magnitude and high/low coherence interpretation
- release-readiness checks for tutorials, toy data, input schema, dependencies, and reproducible environment files
- cross-sectional compositional analysis when paired linkage does not exist
- descriptive baseline support when only limited metadata are available
- identifying when the dataset is not ready for a stronger analysis path

## Do Not Use This Skill For

- responder prediction
- clinical recommendation logic
- automated biological validation strategies or treatment-selection decision trees
- outcome-model branches
- formal clinical-trial power calculation or minimum-detectable-effect claims
- manuscript figure assembly
- manuscript figure or table generation pipelines
- study-local report generation
- customer-facing product claims

If the user asks for those excluded tasks, state the boundary clearly and stay within descriptive or methodological support.

## Release-Readiness Checks

When the user asks whether the skill is ready for community release, adoption, reviewer testing, tutorials, input format, or environment reproducibility, check for these bundled resources:

- a five-minute toy vignette under `tutorials/`
- a tiny artificial toy dataset under `examples/toy_dataset/`
- explicit input schema guidance under `references/input-data-structure.md`
- dependency and environment templates under `env/`
- clear warnings that toy outputs are workflow demonstrations, not biological validation

Do not claim that these resources make the package production-ready or fully cross-platform. Treat them as adoption and review aids.

## Dataset Roles

Assign one dataset role before interpreting portability, replication, or stress-test results:

- Main biological application: the primary manuscript or project dataset being interpreted for its own biological question.
- Fiber replication: an independent dataset with fiber-specific intervention design, exposure metadata, and enough comparable endpoints to test whether a fiber-related finding reproduces.
- Strong perturbation stress-test: a dataset with dense within-subject perturbation structure that can stress-test response geometry and workflow stability but is not biological replication.
- Individualized response stress-test: a repeated-measures dataset suited to checking whether subject-level trajectories, pairability, and heterogeneous directions are handled conservatively.
- Subtle/mixed diet stress-test: a dataset with weaker or mixed dietary contrast suited to testing whether the workflow avoids over-claiming when response signals are small or heterogeneous.
- Exclude: a dataset that lacks usable microbiome abundance data, metadata overlap, valid sample IDs, or a defensible role for the requested comparison.

Do not treat stress-test datasets as biological replication. Do not reuse manuscript-primary datasets as external portability validation. For David 2014, Animal-arm-only geometry should be described as dense within-subject diet perturbation diagnostic, not fiber replication.

David-style runs are magnitude/strong-perturbation implementation stress tests, not biological validation. Palleja-style runs are antibiotic-recovery routing and strong-perturbation implementation stress tests. Palleja pathway-space results are biological-context implementation contrasts, not pathway activity or mechanism.

## Core Workflow

Always work in this order:

1. Identify the abundance or taxonomy table and the metadata table.
2. Audit sample-ID usability, data orientation, value scale, and metadata overlap.
3. Route into the strongest safe workflow.
4. Run the backend only if the required inputs are present.
5. Interpret results conservatively and say what is not justified.

## Architecture

Treat the skill as a self-contained orchestration package:

- `scripts/` is the packaged compute layer used by this skill.
- `references/` documents when to validate inputs, which backend path to run, and how to interpret outputs conservatively.
- standardized geometry-ready dataset bundles may be run directly when they provide compatible abundance data, metadata, and explicit pairing maps

This means:

- do not reduce the skill to static documentation
- do use the backend for actual computation when the inputs are sufficient
- do use the readability scripts when backend outputs need a lighter human-facing summary
- do use the packaged scripts and references when a neutral execution surface is needed
- do not let the skill drift into a product-facing application or customer workflow
- do not present backend outputs as automated clinical or predictive conclusions
- do not depend on local development paths outside this skill folder

## Routing States

Route the task into one of four states:

### Paired Compositional Workflow

Use when metadata support linked repeated measures, usually with:

- `sample_id`
- `subject_id`
- `timepoint` or an equivalent Before/After field

This is the preferred route for response interpretation. Use the backend to validate pairability, compute CLR/Aitchison quantities when counts are available, and summarize per-subject paired geometry.

### Cross-Sectional Compositional Workflow

Use when the abundance table and metadata are usable but paired linkage is absent or incomplete. Focus on structure, composition, and restrained group-level interpretation. Use geometry-aware language internally as a guardrail, not as the main user-facing concept.

### Descriptive Baseline Support

Use when only limited group or cohort metadata are available. Support descriptive summaries, compositional positioning, and data-readiness advice. Do not frame this as predictive or clinical inference.

### Cleanup-Needed / Not-Ready Path

Use when:

- `sample_id` matching is missing or ambiguous
- the table is too malformed to route safely
- metadata cannot be aligned to the abundance table
- required paired fields are absent for a requested paired workflow

In this path, give the strongest safe diagnosis of what is wrong and what minimum cleanup would unlock a stronger workflow.

For more detail on routing, read [references/workflow-routing.md](references/workflow-routing.md).

## Backend Usage

This skill uses the packaged scripts under `scripts/` as its compute engine so the skill remains self-contained for packaging.

For standardized geometry-ready microbiome dataset bundles, direct backend execution is supported when the bundle provides:

- a count-like abundance table passed as `--feature_table` or `--counts`
- metadata passed as `--metadata`
- explicit baseline/post pairing passed as `--pairing_map`
- output location passed as `--outdir`

The standardized pairing path uses `is_baseline` and `is_post` where present. Adapter metadata is not required for the Palleja 2018 and David 2014 direct backend stress-test examples.

Prefer explicit pairing maps. Record endpoint rules, sample overlap, pairability, seed, permutation count, and claim boundary for every run. If pairing is ambiguous, refuse the paired route and explain the minimum metadata or pairing-map fields needed.

### Always Start With

- `scripts/check_inputs.R`

Use it to validate counts, metadata, distance inputs, sample overlap, and Before/After pairability.

### Then Route With

- `scripts/recommend_workflow.R`

Use it when the appropriate compute path is not yet obvious from the audited inputs.

### Compute Modules

- `scripts/compute_clr_aitchison.R`
  - use when raw counts or count-like taxonomy tables are available
- `scripts/paired_response_geometry.R`
  - use for paired response summaries when Before/After linkage exists
- `scripts/export_summary.R`
  - use after backend execution to collect a manifest and summary; accepts `--outdir` or `--run_dir`
- `scripts/export_narrative_summary.R`
  - use after backend TSVs exist and a readable note is needed; accepts `--outdir` or `--run_dir`
- `scripts/plot_summary.R`
  - use when simple summary figures would help, but keep them lightweight and non-manuscript; accepts `--outdir` or `--run_dir`
- `scripts/pseudocount_sensitivity_check.R`
  - use when paired count-like data are available and the user needs a targeted comparison of paired response geometry across pseudocount settings; keep pairings, endpoints, and feature filters fixed
- `scripts/coherence_power_guide.R`
  - use when the user needs a conservative a priori operating-context guide for directional coherence across sample-size and effect-size assumptions; do not describe it as a validated power calculator
- `scripts/decision_flow_summary.R`
  - use after group-level magnitude/coherence outputs exist and the user needs an accessible decision-tree style summary with cautious biological follow-up suggestions; do not describe it as a clinical decision tree or validated responder classifier

Read [references/backend-modules.md](references/backend-modules.md) before using a module you have not loaded recently. Read [references/zero-handling-and-power.md](references/zero-handling-and-power.md) before running pseudocount sensitivity or sample-size planning modules. Read [references/decision-flow.md](references/decision-flow.md) before producing decision-tree style interpretation outputs.

When working inside this project, treat the packaged scripts as the local compute implementation for this skill, not as a separate analysis framework with its own scientific logic.

For the readable layer:

- keep comments short and descriptive
- prefer 3 to 6 comments per available module
- end with one compact summary paragraph
- explicitly separate supported interpretation from unsupported inference

## Zero-Handling and Sample-Size Planning Add-On

Use the v6.1 add-on when the user asks whether a coherence result is robust to pseudocount choice or how many paired subjects might be needed in a future endpoint-aligned study.

For pseudocount sensitivity:

- require paired count-like data and fixed endpoint definitions
- prefer explicit `--pairing_map`
- compare at least `0.5` and `1.0` when this matches the manuscript-style sensitivity question
- report changes in group-level magnitude and mean cosine
- say whether the qualitative call changed
- never claim pseudocount invariance from a narrow check

For sample-size operating guidance:

- use `scripts/coherence_power_guide.R` as an a priori simulation screen
- report assumptions, seed, sample-size grid, effect-size grid, feature count, replicate count, permutation count, alpha, and detection rate
- describe outputs as operating-context guidance, not formal clinical-trial power, universal minimum detectable effect, or proof that an empirical null result is false negative

## Decision-Flow Accessibility Add-On

Use the v6.2 decision-flow add-on when the user asks how to make magnitude/coherence outputs easier for clinicians, biologists, or non-statistical readers to use.

For decision-flow summaries:

- use `scripts/decision_flow_summary.R` after group-level magnitude and coherence outputs exist
- classify the result as one of four reader-friendly states: limited movement with weak alignment, large movement with weak alignment, magnitude-limited organized movement, or large coordinated movement
- recommend follow-up checks rather than clinical actions
- emphasize endpoint alignment, feature-space sensitivity, zero-handling robustness, baseline dependence, subgroup structure, and external replication where relevant
- never present the output as a clinical decision tree, treatment recommendation, responder classifier, mechanistic validation, or universal threshold rule

## Geometry Guardrail

Keep geometry-aware logic as an internal guardrail.

- Prefer compositional workflows based on CLR and Aitchison when counts support them.
- Treat distance-only PCoA geometry as a fallback, not the preferred default.
- Do not lead with Euclidean or ordination jargon unless the user asks for mathematical detail.
- Do not over-claim directional coherence if the data are cross-sectional or only loosely paired.

## Interpretation Rules

Interpretation must stay conservative.

- State what the dataset supports.
- State what remains uncertain.
- State what is not justified.
- Prefer descriptive ecological language over causal or clinical language.
- Do not imply intervention efficacy, responder classification, or individualized recommendation.

Read [references/interpretation-scope.md](references/interpretation-scope.md) before drafting result language.
Read [references/readability-layer.md](references/readability-layer.md) before generating the narrative layer.

## Practical Operating Pattern

For most tasks:

1. Inspect the provided tables and determine whether they are counts, relative abundances, transformed values, or unclear.
2. Run `check_inputs.R` if the structure is ambiguous, if sample matching is uncertain, or if paired analysis is being considered.
3. If counts are available and the dataset is compositionally suitable, run `compute_clr_aitchison.R`.
4. If paired metadata are present, run `paired_response_geometry.R`.
5. Use `export_summary.R` when you need a machine-readable run manifest.
6. If a readable note is needed, run `export_narrative_summary.R`.
7. If lightweight figures would help, run `plot_summary.R`.
8. Summarize the outcome in restrained language.

## References To Load On Demand

- Routing details: [references/workflow-routing.md](references/workflow-routing.md)
- Backend details: [references/backend-modules.md](references/backend-modules.md)
- Interpretation boundaries: [references/interpretation-scope.md](references/interpretation-scope.md)
- Trial-run guidance: [references/trial-run-guidance.md](references/trial-run-guidance.md)
- Claim boundaries: [references/claim-boundaries.md](references/claim-boundaries.md)
- Route examples: [references/route-examples.md](references/route-examples.md)
- Readability layer: [references/readability-layer.md](references/readability-layer.md)
- Version note: [references/changelog-v3.md](references/changelog-v3.md)
- V5.2 release note: [references/changelog-v5-2.md](references/changelog-v5-2.md)
- V6 release note: [references/changelog-v6.md](references/changelog-v6.md)

## Packaging Note

The backend scripts in this skill are packaged under `scripts/` so the skill remains self-contained for ZIP packaging.

Draft wrapper manifests or local trial artifacts are not proof of a validated live MCP server.
