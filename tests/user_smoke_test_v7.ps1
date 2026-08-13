$ErrorActionPreference = 'Stop'
$out = 'tmp_user_smoke'
if (Test-Path $out) { Remove-Item -LiteralPath $out -Recurse -Force }
function Run-R([string[]]$a) { & Rscript @a; if ($LASTEXITCODE -ne 0) { throw "R command failed: $($a -join ' ')" } }
function Pass([string]$x) { Write-Host "PASS: $x" -ForegroundColor Green }
function Check([bool]$ok,[string]$x) { if(-not $ok){throw "FAIL: $x"}; Pass $x }
try {
  Run-R @('scripts/paired_response_geometry.R','--feature_table','examples/toy_dataset/feature_table.tsv','--metadata','examples/toy_dataset/metadata.tsv','--pairing_map','examples/toy_dataset/pairing_map.tsv','--outdir',"$out/paired",'--samples-in-rows','true'); $g=Import-Csv "$out/paired/group_geometry.tsv" -Delimiter "`t"; Check ($g.Count -eq 2 -and $null -ne $g[0].mean_loo_reference_cosine) 'paired LOO toy'
  Run-R @('scripts/paired_signflip_null.R','--vectors','examples/vector_tool_toy.tsv','--outdir',"$out/sign1",'--seed','17','--permutations','99'); Run-R @('scripts/paired_signflip_null.R','--vectors','examples/vector_tool_toy.tsv','--outdir',"$out/sign2",'--seed','17','--permutations','99'); Check ((Get-FileHash "$out/sign1/paired_signflip_null.tsv").Hash -eq (Get-FileHash "$out/sign2/paired_signflip_null.tsv").Hash) 'deterministic group-specific sign-flip'
  Run-R @('scripts/between_group_geometry_contrast.R','--vectors','examples/vector_tool_toy.tsv','--outdir',"$out/between",'--seed','17','--permutations','99'); $b=Import-Csv "$out/between/between_group_geometry_contrast.tsv" -Delimiter "`t"; Check ([math]::Abs([double]$b.mean_direction_cosine+1) -lt 1e-12) 'between-group contrast and jackknife'
  Run-R @('scripts/longitudinal_return_geometry.R','--vectors','examples/three_timepoint_return_toy.tsv','--outdir',"$out/return"); $r=Import-Csv "$out/return/longitudinal_return_geometry.tsv" -Delimiter "`t"; Check (([math]::Abs([double]$r[0].q_return_orientation-0.894427191) -lt 1e-7) -and ([math]::Abs([double]$r[0].rho_residual_to_away-0.632455532) -lt 1e-7) -and ([math]::Abs([double]$r[1].q_return_orientation-0.948683298) -lt 1e-7)) 'return q/rho hand-check'
  Run-R @('scripts/influence_diagnostics.R','--vectors','examples/vector_tool_toy.tsv','--outdir',"$out/influence"); Check ((Import-Csv "$out/influence/influence_diagnostics.tsv" -Delimiter "`t").Count -eq 6) 'influence diagnostics'
  Run-R @('scripts/directional_feature_stability.R','--vectors','examples/vector_tool_toy.tsv','--outdir',"$out/features"); $f=Import-Csv "$out/features/directional_feature_stability.tsv" -Delimiter "`t"; Check ($f.Count -eq 2 -and $null -ne $f[0].signed_mean_contribution) 'feature stability'
  Run-R @('scripts/response_geometry_simulator.R','--outdir',"$out/simulator",'--seed','7'); $s=Import-Csv "$out/simulator/response_geometry_simulator.tsv" -Delimiter "`t"; Check (($s.scenario | Sort-Object) -join ',' -eq 'magnitude_only_random_direction,mixed_response,null_response,opposing_subgroups,shared_direction') 'all five simulator scenarios'
  exit 0
} catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }
