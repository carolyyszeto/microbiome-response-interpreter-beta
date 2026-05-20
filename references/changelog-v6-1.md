# Changelog V6.1

## Release Purpose

V6.1 adds practical support for two reviewer-facing workflow needs:

1. targeted pseudocount sensitivity checks for CLR/Aitchison response-geometry outputs
2. simulation-based a priori sample-size and operating-context guidance for directional coherence

## Added Scripts

- `scripts/pseudocount_sensitivity_check.R`
  - reruns paired CLR response geometry over a pseudocount grid
  - exports group-level and subject-level sensitivity tables
  - compares each setting with a reference pseudocount

- `scripts/coherence_power_guide.R`
  - simulates paired response vectors under null, random-direction, and shared-direction assumptions
  - estimates diagnostic detection rate across sample-size and effect-size grids
  - exports a compact planning table and methods note

## Added Reference

- `references/zero-handling-and-power.md`
  - describes when to use the new scripts
  - provides conservative manuscript-style wording
  - states claim boundaries for pseudocount and sample-size outputs

## Scope Boundary

These additions improve practical robustness checking and study-planning support. They do not turn the skill into a validated power calculator, clinical-trial design platform, predictive model, or manuscript computation engine.
