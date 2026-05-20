# Changelog V6

## Release Purpose

V6 is the V10 documentation-support release of `microbiome-response-interpreter`.
It keeps the v5.2 backend interface and updates the live skill identity to
`microbiome-response-interpreter-v6`.

## Documentation Additions

- Added explicit David/Palleja trial-run claim boundaries.
- Added route examples for David-style strong-perturbation runs, Palleja antibiotic-recovery routing, Palleja pathway-space contrasts, and probe folders.
- Expanded trial-run guidance to require endpoint rules, sample overlap, pairability, seed, permutation count, and claim boundary for every run.
- Clarified that probe folders are input-readiness and output-shape checks only.

## Scope Boundary

David-style runs are magnitude/strong-perturbation implementation stress tests,
not biological validation. Palleja-style runs are antibiotic-recovery routing and
strong-perturbation implementation stress tests. Palleja pathway-space results
are biological-context implementation contrasts, not pathway activity or
mechanism.

This release does not change backend computation.
