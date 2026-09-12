#Requires -Version 7
<#
.SYNOPSIS
  Exercise the gateway on every wire format clients use.
.EXAMPLE
  $env:LITELLM_API_KEY = "sk-..."; ./smoke-test.ps1 -Model coder-cheap -AnthropicModel claude-haiku-4-5
#>
param(
  [string]$Model = "coder-cheap",
  [string]$AnthropicModel = "claude-haiku-4-5",
  [string]$Base = $(if ($env:LITELLM_BASE_URL) { $env:LITELLM_BASE_URL } else { "http://localhost:4000" })
)
$ErrorActionPreference = "Stop"
$key = if ($env:LITELLM_API_KEY) { $env:LITELLM_API_KEY } elseif ($env:LITELLM_MASTER_KEY) { $env:LITELLM_MASTER_KEY } else { $null }
if (-not $key) { throw "set LITELLM_API_KEY (a virtual key) or LITELLM_MASTER_KEY" }
$auth = @{ Authorization = "Bearer $key" }

function Step($t) { Write-Host "`n== $t ==" -ForegroundColor Cyan }

Step "liveliness"
Invoke-RestMethod -Uri "$Base/health/liveliness" | ConvertTo-Json -Compress

Step "models visible to this key"
(Invoke-RestMethod -Uri "$Base/v1/models" -Headers $auth).data | Sort-Object id | ForEach-Object { " - $($_.id)" }

Step "chat completions ($Model)"
$body = @{ model = $Model; messages = @(@{ role = "user"; content = "Reply with the single word OK." }); max_tokens = 16 } | ConvertTo-Json -Depth 5
Invoke-RestMethod -Method Post -Uri "$Base/v1/chat/completions" -Headers $auth -ContentType "application/json" -Body $body | ConvertTo-Json -Depth 6

Step "responses API ($Model)"
$body = @{ model = $Model; input = "Reply with the single word OK."; max_output_tokens = 16 } | ConvertTo-Json -Depth 5
Invoke-RestMethod -Method Post -Uri "$Base/v1/responses" -Headers $auth -ContentType "application/json" -Body $body | ConvertTo-Json -Depth 6

Step "anthropic messages ($AnthropicModel)"
$h = $auth + @{ "anthropic-version" = "2023-06-01" }
$body = @{ model = $AnthropicModel; max_tokens = 16; messages = @(@{ role = "user"; content = "Reply with the single word OK." }) } | ConvertTo-Json -Depth 5
Invoke-RestMethod -Method Post -Uri "$Base/v1/messages" -Headers $h -ContentType "application/json" -Body $body | ConvertTo-Json -Depth 6

Step "key info"
try { Invoke-RestMethod -Uri "$Base/key/info" -Headers $auth | ConvertTo-Json -Depth 6 } catch { Write-Host "(key/info needs a virtual key; skipped)" }

Write-Host "`nall checks passed" -ForegroundColor Green
