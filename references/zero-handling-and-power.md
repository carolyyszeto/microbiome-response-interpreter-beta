# Zero-handling sensitivity and sample-size planning

Use this reference when the user asks about pseudocount sensitivity, zero handling, robustness of CLR/Aitchison summaries, or prospective sample-size planning for the response-geometry framework.

## Zero-handling sensitivity check

Treat zero handling as part of the analysis definition, not as a cosmetic preprocessing option.

Run `scripts/pseudocount_sensitivity_check.R` when count-like abundance data, metadata, and paired linkage are available. Prefer explicit `--pairing_map`; otherwise allow metadata-based inference only when pairability is unambiguous.

Minimum recommended settings:

```bash
Rscript scripts/pseudocount_sensitivity_check.R \
  --feature_table counts.tsv \
  --metadata metadata.tsv \
  --pairing_map pairing_map.tsv \
  --outdir pseudocount_sensitivity \
  --pseudocounts 0.5,1.0 \
  --reference_pseudocount 0.5
```

For manuscript-style robustness, report:

- the pseudocount grid tested
- whether pairings, endpoint definitions, and feature filters were fixed
- group-level mean subject magnitude and mean cosine at each pseudocount
- absolute and relative change from the reference pseudocount
- whether the qualitative call changed

Do not state that results are pseudocount invariant unless a broad and prespecified zero-handling benchmark supports that conclusion. Safer wording:

> A targeted pseudocount sensitivity check compared the prespecified reference pseudocount with alternative settings under fixed pairing, endpoint definitions, and feature filters. The qualitative response-organization call was or was not materially altered. This check does not replace a systematic zero-handling benchmark.

## A priori sample-size and power guidance

Use `scripts/coherence_power_guide.R` when the user asks how many paired participants may be needed to detect directional coherence under assumed effect sizes.

This script provides a simulation-based planning screen for the skill workflow. It is not a validated clinical-trial power calculator and should not be described as a formal minimum detectable effect. The output depends on assumed feature dimension, noise scale, shared-direction effect size, simulation model, permutation count, and alpha.

Example:

```bash
Rscript scripts/coherence_power_guide.R \
  --outdir power_guide \
  --sample_sizes 10,15,20,30,40,60 \
  --effect_sizes 0,0.35,0.8,1.4 \
  --n_features 500 \
  --n_reps 500 \
  --n_perm 499 \
  --seed 123
```

Report sample-size results as operating-context guidance:

- `n_subjects`
- assumed `effect_size`
- detection rate at `alpha`
- median observed coherence
- median observed-minus-null coherence gap
- simulation settings and seed

Safer wording:

> Under the stated simulation assumptions, detection increased with sample size and shared-direction effect size. These results provide an a priori operating-context guide for planning endpoint-aligned studies, not a validated universal power calculation.

## Interpretation boundaries

Always include these caveats when presenting sensitivity or power outputs:

- sample-size guidance assumes the simulated effect and noise structure
- small arms can miss weak or subgroup-specific shared directions
- opposing subgroups can cancel pooled coherence
- pseudocount results are conditional on fixed feature filtering and endpoint rules
- power guidance should be rerun with feature spaces and endpoint definitions close to the planned study
