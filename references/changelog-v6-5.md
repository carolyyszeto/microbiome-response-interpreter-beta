# Changelog v6.5

Usability patch for toy workflow execution from Windows PowerShell / VS Code terminals.

## Added

- PowerShell / VS Code one-line smoke-test commands for the toy workflow.

## Changed

- Toy workflow documentation now uses `--samples_in_rows true` for paired response geometry and pseudocount sensitivity.
- `decision_flow_summary.R` now auto-detects group-level outputs from `paired_response_geometry.R`, including `mean_subject_magnitude` and `mean_cosine`.

## Boundaries

- No change to the core response-geometry method.
