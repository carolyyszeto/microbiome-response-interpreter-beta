# V7 engine update report

Starting main HEAD: `6d6112e841fbf6db0db52ba3724f84e2343fff6a`. Historical tag `v6.5-beta` resolves to `7ebfe74d2eaf480ec1a862b141d81ec33f4f4a7a` and was not changed.

## Estimator and interpretation

Paired directional organization now uses a leave-one-participant-out reference: the focal participant is excluded from its group mean direction. The former full-sample cosine remains available only as `legacy_full_sample_mean_cosine`. The pseudocount check uses the same LOO estimator. The v7 interpretation layer starts with the biological question and descriptive interpretation, then limitations, statistics, and the mathematical definition; it supplies no responder classes or validated thresholds.

## Verification

- Paired artificial-toy smoke test passed (8 pairs, two groups) with LOO output and separately labelled legacy output.
- Pseudocount sensitivity smoke test passed using the LOO estimator.
- Three-timepoint return toy passed: all constructed trajectories had `q=1` and `rho=0.5`.
- Simulator passed all five scenarios, including an NA LOO result for zero vectors.
- Deterministic LOO exclusion, sign-flip seed reproducibility, group separation, and participant-deletion diagnostics passed their smoke runs; sign flipping multiplies vectors by +/-1 and records magnitude preservation.

## Scope/security audit

No real cohort data, manuscript-specific pipelines, prohibited reserve-work terms, local/private paths, or identifiers were added. No secrets were detected in the tracked change set.

## Open issues

The six new tools accept a simple vector-table interface (`subject_id`, optional `group`, and numbered `v*` columns; return geometry uses `a*`/`e*`). A dedicated automated test harness and README/release-surface update are intentionally deferred.
