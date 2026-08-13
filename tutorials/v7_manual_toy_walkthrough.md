# v7 manual microbiome toy walkthrough

This artificial example asks: do paired microbial-community changes within each supplied group point in a broadly similar direction, and which named features contribute descriptively to that direction? It does not define responders, biological cutoffs, biomarkers, mechanisms, efficacy, or recovery.

Open PowerShell at the repository root. Choose a new output folder name, then run the following commands exactly.

```powershell
$out = "tmp_v7_manual_toy"
Rscript scripts/paired_response_geometry.R --feature_table examples/toy_dataset/feature_table.tsv --metadata examples/toy_dataset/metadata.tsv --pairing_map examples/toy_dataset/pairing_map.tsv --outdir $out --samples-in-rows true
Rscript scripts/paired_signflip_null.R --vectors "$out/participant_response_vectors.tsv" --outdir "$out/signflip" --seed 17 --permutations 999
Rscript scripts/between_group_geometry_contrast.R --vectors "$out/participant_response_vectors.tsv" --outdir "$out/between_group" --seed 17 --permutations 999
Rscript scripts/influence_diagnostics.R --vectors "$out/participant_response_vectors.tsv" --outdir "$out/influence"
Rscript scripts/directional_feature_stability.R --vectors "$out/participant_response_vectors.tsv" --outdir "$out/feature_stability"
```

Open `$out/group_geometry.tsv` first. It describes the size and LOO organization of paired community movement for each supplied group; it is a descriptive answer to whether movements look similarly directed under the defined endpoints. The legacy full-sample quantity is explicitly labelled and is not the v7 estimator.

Then open `$out/participant_response_vectors.tsv`. Each row is one participant and its group. All remaining columns are actual CLR response dimensions named after the input microbial features (for example `Bacteroides`), so the downstream tools use the same biology-facing dimensions without manual reformatting.

Open `$out/signflip/paired_signflip_null.tsv` for group-specific paired sign-flip diagnostic null summaries; this checks directional organization relative to pairing-preserving sign flips, not efficacy. Open `$out/between_group/between_group_geometry_contrast.tsv` and its jackknife companion to compare group-level movement magnitude and LOO organization descriptively. Open `$out/influence/influence_diagnostics.tsv` to see how deleting one participant changes the group LOO summary. Open `$out/feature_stability/directional_feature_stability.tsv` for descriptive signed feature contributions and their participant stability; these are not biomarkers or causal features.

Return geometry is a separate artificial three-timepoint exercise because it needs distinct away (A), return (R), and endpoint residual (E) vectors:

```powershell
Rscript scripts/longitudinal_return_geometry.R --vectors examples/three_timepoint_return_toy.tsv --outdir "$out/return_geometry"
```

Open `$out/return_geometry/longitudinal_return_geometry.tsv`. Positive `q_return_orientation` means movement is oriented back toward baseline; it does not mean complete recovery. `rho_residual_to_away` compares residual endpoint distance with away-movement distance.
