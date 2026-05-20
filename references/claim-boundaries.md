# Claim Boundaries

Use this reference before drafting any David/Palleja trial-run interpretation or package note.

## Core Boundary

This skill supports conservative data-readiness routing, backend execution, and descriptive response-geometry summaries. It does not support claims of clinical prediction, treatment effect, mechanism, pathway activity, biological validation, external validation, or framework validation.

## David-Style Runs

David-style runs are magnitude and strong-perturbation implementation stress tests. They can be used to check sample overlap, endpoint routing, pairability, displacement magnitude, output shape, logging, and conservative readable summaries.

Allowed phrasing:

- strong-perturbation stress test
- magnitude stress test
- dense within-subject perturbation routing check
- large displacement without clear directional organization, when supported by the run outputs

Do not describe David-style runs as fiber replication, clinical evidence, biological confirmation, or validation of the response-geometry framework.

## Palleja-Style Runs

Palleja-style runs are antibiotic-recovery routing and strong-perturbation implementation stress tests. Species-space and pathway-space outputs may be used as biological-context implementation contrasts.

Allowed phrasing:

- antibiotic-recovery routing stress test
- strong-perturbation stress test
- early disruption organization, when supported by the run outputs
- reversal-like recovery in species/pathway geometry, when supported by the run outputs

Do not describe pathway-space summaries as pathway activity, pathway mechanism, clinical recovery evidence, treatment-effect evidence, or external validation.

## Probe Folders

Probe folders are input-readiness and output-shape checks only unless they also include enough metadata and provenance to support a fuller rerun.

Require these fields or files before using a probe folder as a stronger example:

- abundance input path and format
- metadata input path and format
- endpoint rules
- sample overlap summary
- explicit pairing map or documented refusal of pairing
- seed
- permutation count
- command log
- checksum or manifest
- claim boundary

Use conservative refusal when pairing is ambiguous. State the missing fields rather than trying to infer a paired route from sample names alone.

