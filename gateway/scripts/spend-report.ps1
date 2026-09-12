#Requires -Version 7
<#
.SYNOPSIS
  Spend report from the gateway for the last N days: grouped totals and per-day/per-model usage.
.EXAMPLE
  $env:LITELLM_MASTER_KEY = "sk-..."; ./spend-report.ps1 -Days 30 -GroupBy api_key
#>
param(
  [int]$Days = 30,
  [ValidateSet("api_key", "team", "customer")][string]$GroupBy = "api_key",
  [string]$Base = $(if ($env:LITELLM_BASE_URL) { $env:LITELLM_BASE_URL } else { "http://localhost:4000" })
)
$ErrorActionPreference = "Stop"
if (-not $env:LITELLM_MASTER_KEY) { throw "set LITELLM_MASTER_KEY (admin)" }
$auth = @{ Authorization = "Bearer $($env:LITELLM_MASTER_KEY)" }
$start = (Get-Date).AddDays(-$Days).ToString("yyyy-MM-dd"); $end = (Get-Date).ToString("yyyy-MM-dd")

Write-Host "== spend by $GroupBy, $start .. $end ==" -ForegroundColor Cyan
try {
  $rep = Invoke-RestMethod -Uri "$Base/global/spend/report?start_date=$start&end_date=$end&group_by=$GroupBy" -Headers $auth
  $rows = if ($rep -is [array]) { $rep } elseif ($rep.data) { $rep.data } else { @($rep) }
  $total = 0.0
  foreach ($r in $rows) {
    $ident = $r.group_by_day ?? $r.api_key ?? $r.key_alias ?? $r.team_alias ?? $r.team_id ?? $r.customer ?? ""
    $spend = [double]($r.total_spend ?? $r.spend ?? 0); $total += $spend
    "{0,-40} `${1,10:F4}" -f ([string]$ident).Substring(0, [Math]::Min(40, ([string]$ident).Length)), $spend
  }
  "{0,-40} `${1,10:F4}" -f "TOTAL", $total
} catch { Write-Host "(report endpoint unavailable: $($_.Exception.Message))" }

Write-Host "`n== per-day, per-model (daily activity) ==" -ForegroundColor Cyan
try {
  $act = Invoke-RestMethod -Uri "$Base/user/daily/activity?start_date=$start&end_date=$end" -Headers $auth
  $days = if ($act.results) { $act.results } else { $act }
  $agg = @{}
  foreach ($d in $days) {
    $models = $d.breakdown.models
    if (-not $models) { continue }
    foreach ($p in $models.PSObject.Properties) {
      $met = $p.Value.metrics ?? $p.Value
      if (-not $agg[$p.Name]) { $agg[$p.Name] = @{ spend = 0.0; req = 0; in = 0; out = 0; cache = 0 } }
      $a = $agg[$p.Name]
      $a.spend += [double]($met.spend ?? 0); $a.req += [int]($met.api_requests ?? 0)
      $a.in += [int]($met.prompt_tokens ?? 0); $a.out += [int]($met.completion_tokens ?? 0)
      $a.cache += [int]($met.cache_read_input_tokens ?? 0)
    }
  }
  "{0,-30} {1,9} {2,12} {3,12} {4,12} {5,10}" -f "model", "requests", "input tok", "cache read", "output tok", "spend"
  foreach ($kv in ($agg.GetEnumerator() | Sort-Object { -$_.Value.spend })) {
    $a = $kv.Value
    "{0,-30} {1,9} {2,12} {3,12} {4,12} `${5,9:F4}" -f $kv.Key.Substring(0, [Math]::Min(30, $kv.Key.Length)), $a.req, $a.in, $a.cache, $a.out, $a.spend
  }
} catch { Write-Host "(daily activity unavailable: $($_.Exception.Message))" }
