# Readability Layer

## Purpose

The current package retains the lightweight readability layer that was added in the earlier V3.1 iteration.

The design is intentionally layered:

1. TSV backend truth
2. readable comment sentences
3. optional lightweight figures

## Layer 1: TSV Backend Truth

The TSV outputs remain the primary machine-readable source of truth.

Examples:

- `check_inputs_summary.tsv`
- `workflow_recommendation.tsv`
- `compute_clr_aitchison_summary.tsv`
- `paired_vectors.tsv`
- `group_geometry.tsv`
- `backend_summary.tsv`

These tables should not be replaced by prose.

## Layer 2: Readable Comment Sentences

Use `scripts/export_narrative_summary.R` when users need a lighter interpretation layer.

Expected outputs:

- `module_comments.tsv`
- `narrative_summary.md`

Style rules:

- 3 to 6 short comments per available module
- comments should be descriptive, not promotional
- comments should state what the data support
- comments should not imply prediction, clinical action, or causal proof

The final paragraph should behave like a short assistant note:

- compact
- readable
- explicit about unsupported inference

## Layer 3: Optional Lightweight Figures

Use `scripts/plot_summary.R` only when simple visuals would improve readability.

Expected figures may include:

- `magnitude_by_subject.png`
- `group_geometry_overview.png`
- `structure_overview.png`

Figure rules:

- simple exploratory summary only
- no manuscript polish
- no figure-panel language
- no caption-style storytelling

## Scope Boundary

The readability layer must not become:

- a manuscript production layer
- a clinical report layer
- a product-facing application layer

It exists to help users read backend outputs quickly while preserving conservative interpretation.
