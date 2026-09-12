#Requires -Version 7
<#
.SYNOPSIS
  Install the personal profile on this Windows machine (OpenCode, skills, Claude Code helper, Codex).
  Never overwrites an existing opencode.json / config.toml without -Force; writes *.new instead.
#>
param([switch]$Force)
$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$Cfg  = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME ".config" }
$OC   = Join-Path $Cfg "opencode"
$SK   = Join-Path $HOME ".agents\skills"
$CL   = Join-Path $HOME ".claude"
$CX   = Join-Path $HOME ".codex"

function Place($src, $dst) {
  if ((Test-Path $dst) -and -not $Force) {
    Copy-Item $src "$dst.new" -Force; Write-Host "  exists: $dst -> wrote $dst.new (merge by hand or use -Force)"
  } else {
    Copy-Item $src $dst -Force; Write-Host "  wrote:  $dst"
  }
}

Write-Host "OpenCode -> $OC"
New-Item -ItemType Directory -Force (Join-Path $OC "agents") | Out-Null
New-Item -ItemType Directory -Force (Join-Path $OC "commands") | Out-Null
Place (Join-Path $Root "clients\opencode\opencode.json") (Join-Path $OC "opencode.json")
Place (Join-Path $Root "clients\opencode\AGENTS.md") (Join-Path $OC "AGENTS.md")
Copy-Item (Join-Path $Root "clients\opencode\agents\*.md") (Join-Path $OC "agents") -Force
Copy-Item (Join-Path $Root "clients\opencode\commands\*.md") (Join-Path $OC "commands") -Force
Write-Host "  agents and commands copied"

Write-Host "Skills -> $SK"
New-Item -ItemType Directory -Force $SK | Out-Null
Get-ChildItem (Join-Path $Root "skills") -Directory | ForEach-Object {
  $dst = Join-Path $SK $_.Name
  if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
  Copy-Item $_.FullName $dst -Recurse
  Write-Host "  $($_.Name)"
}
$claudeSkills = Join-Path $CL "skills"
if (-not (Test-Path $claudeSkills)) {
  New-Item -ItemType Directory -Force $CL | Out-Null
  try { New-Item -ItemType Junction -Path $claudeSkills -Target $SK | Out-Null; Write-Host "  linked $claudeSkills -> $SK" }
  catch { Write-Host "  (could not create junction for ~/.claude/skills; copy manually)" }
}

Write-Host "Sandbox policy -> $HOME\.srt-settings.json"
Place (Join-Path $Root "clients\opencode\srt-settings.json") (Join-Path $HOME ".srt-settings.json")
Write-Host "  use: npm i -g @anthropic-ai/sandbox-runtime; npx @anthropic-ai/sandbox-runtime windows-install (alpha); srt opencode"

Write-Host "Claude Code -> $CL"
New-Item -ItemType Directory -Force $CL | Out-Null
Copy-Item (Join-Path $Root "clients\claude-code\get-gateway-key.ps1") (Join-Path $CL "get-gateway-key.ps1") -Force
Copy-Item (Join-Path $Root "clients\claude-code\settings.json") (Join-Path $CL "settings.gateway.json") -Force
Write-Host "  wrote:  get-gateway-key.ps1, settings.gateway.json (merge into settings.json; set apiKeyHelper to the .ps1)"

Write-Host "Codex -> $CX"
New-Item -ItemType Directory -Force $CX | Out-Null
Place (Join-Path $Root "clients\codex\config.toml") (Join-Path $CX "config.toml")

@"

Next:
  1. Create keys on the gateway host:
       gateway/scripts/create-key.ps1 -Alias opencode -MaxBudget 50
       gateway/scripts/create-key.ps1 -Alias claude-code -MaxBudget 50
       gateway/scripts/create-key.ps1 -Alias codex -MaxBudget 50
  2. Persist in your profile (`$PROFILE):
       `$env:LITELLM_API_KEY = "<opencode or codex key>"
       `$env:LITELLM_CLAUDE_CODE_KEY = "<claude-code key>"
  3. Claude Code settings.json: "apiKeyHelper": "powershell -NoProfile -File $($CL -replace '\\','\\\\')\\get-gateway-key.ps1"
  4. If the gateway is not on localhost:4000, edit the baseURL / ANTHROPIC_BASE_URL / base_url values.
  5. opencode -> /models should list the gateway aliases.
"@
