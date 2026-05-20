# Workflow Routing

## Purpose

This file summarizes how the current packaged skill should route a taxonomy table plus metadata into the correct analysis state.

## Input Assumptions

Common starting inputs:

- one taxonomy or abundance table
- one metadata table

Preferred minimal metadata field:

- `sample_id`

Additional fields unlock stronger workflows:

- `subject_id`
- `group` or `arm`
- `timepoint`, `phase`, `visit`, or equivalent Before/After label

## Route 1: Paired Compositional Workflow

Use when:

- the abundance table is usable
- metadata and abundance table can be matched by sample ID
- repeated measures can be linked by subject
- Before/After or equivalent paired states can be inferred

Preferred backend sequence:

1. `check_inputs.R`
2. `compute_clr_aitchison.R` when counts are available
3. `paired_response_geometry.R`
4. `export_summary.R`

Interpretation focus:

- paired displacement
- within-group directional consistency
- conservative response summaries

## Route 2: Cross-Sectional Compositional Workflow

Use when:

- abundance and metadata are usable
- paired linkage is absent, incomplete, or unreliable
- the task is group-level structure or descriptive compositional comparison

Preferred behavior:

- perform readiness assessment
- recommend compositional methods
- stay descriptive unless the user explicitly requests deeper method detail

`compute_clr_aitchison.R` may still be useful when counts are available, but `paired_response_geometry.R` should not be used unless true pairing exists.

## Route 3: Descriptive Baseline Support

Use when:

- the data are usable
- metadata are limited
- there is enough structure for basic descriptive support but not strong paired interpretation

Support:

- table audit
- baseline descriptive summaries
- workflow advice
- next-step data requirements

Do not convert this route into a prediction or responder-analysis path.

## Route 4: Cleanup-Needed / Not-Ready

Use when:

- sample matching fails
- orientation is ambiguous and cannot be resolved safely
- metadata fields needed for the requested task are missing
- the abundance table is too malformed for direct compute use

Expected output:

- state what is broken
- state the minimum fix needed
- avoid pretending the data support stronger claims

## Routing Priority

When multiple routes appear possible, prefer:

1. paired compositional workflow
2. cross-sectional compositional workflow
3. descriptive baseline support
4. cleanup-needed / not-ready

Only choose a stronger route when the required structure is genuinely present.
