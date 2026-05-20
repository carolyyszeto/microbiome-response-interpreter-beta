# Decision Flow for Reader-Friendly Interpretation

## Purpose

Use this reference when a user asks for a simplified decision tree, clinician-friendly interpretation, biological follow-up strategy, or reader-facing explanation of response magnitude and directional coherence.

The decision flow is an interpretation aid. It is not a clinical decision tool, diagnostic algorithm, responder classifier, or substitute for endpoint-aligned biological validation.

## Required Inputs

Before using the decision flow, confirm that the analysis has at least:

- a paired baseline-to-follow-up response design, or a clearly documented paired contrast
- group-level response magnitude or a comparable magnitude summary
- group-level directional coherence or a comparable alignment summary
- a permutation-null or other diagnostic reference when available
- bootstrap, leave-one-out, pseudocount, feature-space, or endpoint-sensitivity context when available

If these are missing, present the decision flow as a conceptual checklist only.

## Reader-Friendly Four-State Interpretation

Use plain-language labels before mathematical terms.

| Pattern | Geometry shorthand | Practical interpretation | Follow-up emphasis |
|---|---|---|---|
| Limited movement, weak alignment | low magnitude + low coherence | little evidence of organized group-level microbiome remodeling in the tested feature space | check pairability, endpoint choice, sequencing depth, and whether the intervention plausibly affects this layer |
| Large movement, weak alignment | high magnitude + low coherence | participants moved, but not in a shared direction | inspect subgroup structure, baseline dependence, medication/diet adherence, outliers, dispersion, and individual trajectories |
| Limited movement, stronger alignment | low magnitude + higher coherence | a modest but organized response may be present | verify zero handling, bootstrap stability, leave-one-out stability, endpoint alignment, and targeted biological markers |
| Large movement, stronger alignment | high magnitude + higher coherence | a stronger coordinated response is plausible in this feature space | validate with endpoint-aligned multi-omic or host-context data, independent cohort support, and prespecified sensitivity checks |

Avoid hard universal cutoffs unless the user provides study-specific thresholds or simulation-calibrated operating references. Prefer terms such as lower/higher relative to the study distribution, baseline-period reference, permutation-null reference, or prespecified simulation scenario.

## Decision Flow

1. Confirm that the paired contrast is biologically meaningful.
   - If endpoints are not aligned across layers, keep interpretation layer-specific.
   - If sample pairing is incomplete, do not use directional coherence as a strong group descriptor.

2. Ask whether movement size is substantial in the study context.
   - Use Aitchison magnitude, within-study tertiles, baseline-period reference, or simulation operating context.
   - Do not treat magnitude alone as evidence of shared response.

3. Ask whether response directions are aligned above the diagnostic null.
   - Prefer observed-minus-null coherence gap, permutation p value, and bootstrap interval together.
   - Do not overread a nominal p value when feature count is small or sensitivity checks are weak.

4. Combine magnitude and coherence using the four-state interpretation table.
   - State the likely response-organization pattern.
   - State the most relevant caveat.
   - State the next biological or technical check.

5. Choose follow-up strategy according to the pattern.
   - High magnitude + low coherence: prioritize subgroup and baseline-dependence analysis before mechanism claims.
   - Low magnitude + high coherence: prioritize replication, targeted functional or host-context markers, and endpoint alignment.
   - High magnitude + high coherence: prioritize validation of feature-space specificity and external reproducibility.
   - Low magnitude + low coherence: prioritize design adequacy, exposure strength, feature-space suitability, and power/operating-context checks.

## Suggested Output Template

Use this short structure when reporting to non-statistical readers:

```text
Decision-flow summary:
The dataset shows [low/moderate/high] movement size and [weak/moderate/strong] directional alignment in the tested feature space. This pattern is most consistent with [plain-language state]. The main caution is [sample size / endpoint mismatch / zero handling / feature-space sensitivity / baseline dependence]. A reasonable next check is [specific biological or technical follow-up]. This is a response-organization interpretation, not evidence of clinical efficacy or mechanism by itself.
```

## Biological Follow-Up Suggestions by Pattern

### High magnitude + low coherence

Recommended checks:

- plot individual trajectories and identify divergent subgroups
- test baseline microbiome state, diet adherence, medication, sex, age, or disease-state stratification when metadata support it
- compare PERMDISP or distance-to-centroid summaries to assess dispersion-driven effects
- inspect high-magnitude observations with leave-one-out influence
- avoid claiming a shared ecological response

### Low magnitude + higher coherence

Recommended checks:

- verify that coherence remains under pseudocount and zero-handling sensitivity
- check bootstrap and leave-one-out stability
- evaluate targeted biological markers that match the intervention mechanism
- use endpoint-aligned host or functional data if available
- describe as magnitude-limited organized remodeling, not efficacy

### High magnitude + higher coherence

Recommended checks:

- replicate in an independent endpoint-aligned cohort
- verify feature-space robustness and zero-handling sensitivity
- assess whether host-context or functional layers change in the expected direction
- prespecify the coherence endpoint in future studies
- avoid mechanism claims until biological validation is available

### Low magnitude + low coherence

Recommended checks:

- confirm sample pairing, exposure timing, feature filtering, and sequencing depth
- compare against baseline-period or negative-control intervals
- use simulation-based operating guidance to evaluate whether the study is underpowered for expected effects
- avoid interpreting the result as proof of no biological effect

## Claim Boundaries

Allowed wording:

- supports a response-organization interpretation
- suggests heterogeneous movement rather than a shared direction
- suggests magnitude-limited but directionally organized remodeling, if robustness checks support it
- motivates endpoint-aligned validation or subgroup exploration

Avoid wording:

- clinical decision tree
- responder prediction
- treatment recommendation
- mechanistic validation
- proof of efficacy
- universal threshold
- minimum detectable effect
