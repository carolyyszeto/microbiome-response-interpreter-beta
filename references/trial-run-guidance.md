# Trial Run Guidance

David 2014 and Palleja 2018 style trial runs are real-data stress tests for the
microbiome response interpreter skill. They are not validation datasets.

## Allowed Use

Use these runs to check whether the skill:

- detects abundance and metadata inputs conservatively
- records sample-ID overlap
- refuses paired geometry when pairing is ambiguous
- accepts paired geometry when explicit subject baseline/post mapping exists
- keeps endpoint definitions visible
- writes compact machine-readable outputs
- keeps interpretation descriptive and guarded

Acceptable labels include:

- real-data stress test
- input-readiness probe
- metadata-routing probe
- conservative-routing example
- paired-response geometry stress test

## Do Not Claim

Do not describe these runs as:

- biological validation
- external validation
- clinical validation
- predictive validation
- framework validation
- manuscript replication
- responder prediction evidence
- clinical response evidence

## David 2014 Style Runs

David 2014 style runs are useful for dense within-subject perturbation routing.
The current direct trial is an Animal-arm 16S subset with recovered metadata and
explicit baseline/post pairing. It is a strong perturbation stress test, not
fiber replication.

David-style runs should also be treated as magnitude/strong-perturbation
implementation stress tests. They can support comments about displacement size
and directional organization only when those comments are directly supported by
the run outputs.

Important boundaries:

- Selected-table geometry is limited by feature-table overlap.
- Plant and Animal arms must not be merged unless source-compatible feature
  tables and explicit pairing support that route.
- Day 0 should be treated as a transition/start-day if the run documents that
  choice.
- Any readable output should describe geometry behavior only.

Recommended description:

David 2014 was used as a strong perturbation stress test for recovered metadata,
within-subject pairing, sparse-table handling, and conservative readable
summaries.

## Palleja 2018 Style Runs

Palleja 2018 style runs are useful for antibiotic-recovery metadata routing and
paired-response geometry checks. They test whether D0-to-D180 baseline/post
mapping is explicit enough for paired analysis.

Palleja-style runs are antibiotic-recovery routing and strong-perturbation
implementation stress tests. Pathway-space Palleja outputs are biological-context
implementation contrasts, not pathway activity, pathway mechanism, treatment
effect evidence, or clinical recovery evidence.

Important boundaries:

- Standardized metadata with subject/timepoint fields may still be insufficient
  if Before/After pairing is not unambiguous.
- Pairing-map adapters are acceptable when they record subject, baseline sample,
  post sample, endpoint labels, and pairing rule.
- Geometry-only probe folders are not full reproducibility examples unless they
  also include input summaries, command logs, and guardrail summaries.

Recommended description:

Palleja 2018 was used as a metadata-routing and paired-response stress test. The
paired route should be enabled only after explicit D0-to-D180 pairing evidence is
available.

## Documentation Pattern

For each future trial run, document:

- dataset role
- abundance input detected
- metadata input detected
- endpoint rules
- sample overlap status
- subject and endpoint fields
- whether paired analysis is justified
- explicit pairing map path, or reason pairing was refused
- seed
- permutation count
- command or script log availability
- output summary availability
- claim boundary

Keep examples compact. Link to TSV outputs instead of pasting large backend
tables into documentation.

Use conservative refusal when pairing is ambiguous. Probe folders are
input-readiness and output-shape checks only unless they include endpoint rules,
sample overlap, pairability evidence, command logs, run parameters, and claim
boundaries.
