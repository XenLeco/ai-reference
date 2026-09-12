#Requires -Version 7
<#
.SYNOPSIS
  Opt-in installer for the third-party tools assessed in docs/11-community-skills.md.
  Nothing runs unless you name it. Enterprise machines: vendor at a pinned commit instead.
.DESCRIPTION
  Retrieval / graphs / memory: -Serena -Graphify -CodeReviewGraph -Beads
  Methodology:                 -Superpowers -SpecKit [-SpecKitRef vX.Y.Z] -Compound -Aidlc
  Other:                       -Archify -Ponytail
  -Recommended = -Serena -CodeReviewGraph -Beads -SpecKit -Archify (no plugins, no methodology pack)
  Plugin-based tools (superpowers, compound, ponytail) print the in-client commands.
.EXAMPLE
  ./install-community-skills.ps1 -Recommended -SpecKitRef v0.9.0
#>
param(
  [switch]$Serena, [switch]$Graphify, [switch]$CodeReviewGraph, [switch]$Beads,
  [switch]$Superpowers, [switch]$SpecKit, [string]$SpecKitRef = "", [switch]$Compound, [switch]$Aidlc,
  [switch]$Archify, [switch]$Ponytail, [switch]$Recommended
)
$ErrorActionPreference = "Stop"
if ($Recommended) { $Serena = $CodeReviewGraph = $Beads = $SpecKit = $Archify = $true }
if (-not ($Serena -or $Graphify -or $CodeReviewGraph -or $Beads -or $Superpowers -or $SpecKit -or $Compound -or $Aidlc -or $Archify -or $Ponytail)) {
  Get-Help $PSCommandPath -Detailed; exit 1
}

function Hr($t) { Write-Host "`n== $t ==" -ForegroundColor Cyan }
function Need($cmd, $hint) { if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { throw "missing: $cmd ($hint)" } }
function UvTool { param([string[]]$Args)
  if (Get-Command uv -ErrorAction SilentlyContinue) { & uv tool install @Args }
  elseif (Get-Command pipx -ErrorAction SilentlyContinue) { & pipx install $Args[-1] }
  else { throw "install uv (https://docs.astral.sh/uv/) or pipx first" }
}

if ($Serena) {
  Hr "Serena (LSP symbol tools over MCP)"
  UvTool @("-p", "3.13", "serena-agent")
  Write-Host @"
  In each project:  serena project index
  OpenCode (opencode.json):
    "mcp": { "serena": { "type": "local", "command": ["serena","start-mcp-server","--context","ide-assistant","--project","."], "enabled": true } },
    "tools": { "serena*": false }, "agent": { "build": { "tools": { "serena*": true } } }
  Claude Code:  claude mcp add serena -- serena start-mcp-server --context claude-code --project <path>
  Codex (config.toml): [mcp_servers.serena] command = "serena"  args = ["start-mcp-server","--context","codex","--project","."]
  Check context names for your version: serena start-mcp-server --help
"@
}

if ($Graphify) {
  Hr "graphify (code graph + skill -> ~/.agents/skills)"
  UvTool @("graphifyy")
  graphify install --platform agents
  Write-Host "  In a repo: /graphify . ; commit graphify-out/ (ignore graphify-out/cache/); graphify hook install"
  Write-Host "  Gateway for document extraction: `$env:OPENAI_BASE_URL='http://localhost:4000/v1'; `$env:OPENAI_API_KEY=`$env:LITELLM_API_KEY"
}

if ($CodeReviewGraph) {
  Hr "code-review-graph (self-updating code graph over MCP)"
  UvTool @("code-review-graph")
  Write-Host "  In a repo: code-review-graph install --platform opencode   (or claude-code | codex | cursor | gemini-cli)"
  Write-Host "  Review the AGENTS.md diff it makes; scope its ~30 tools per agent."
}

if ($Beads) {
  Hr "beads (bd: task graph memory for agents)"
  if (Get-Command npm -ErrorAction SilentlyContinue) { npm install -g @beads/bd }
  elseif (Get-Command brew -ErrorAction SilentlyContinue) { brew install beads }
  else { throw "install npm (Node.js) first" }
  Write-Host "  In a repo: bd init   (it appends a snippet to AGENTS.md; review the diff)"
}

if ($Superpowers) {
  Hr "superpowers (methodology plugin) — install inside the client"
  Write-Host "  Claude Code:  /plugin install superpowers@claude-plugins-official"
  Write-Host "  Codex:        /plugins  -> Superpowers"
  Write-Host "  OpenCode:     follow https://github.com/obra/superpowers/blob/main/.opencode/INSTALL.md"
  Write-Host "  Telemetry off: `$env:SUPERPOWERS_DISABLE_TELEMETRY = '1'"
  Write-Host "  Then remove overlapping local skills under ~/.agents/skills: debug-reproduce-first, code-review-checklist, pr-writeup"
}

if ($SpecKit) {
  Hr "spec-kit (GitHub spec-driven development CLI)"
  Need git "install git"
  $src = "git+https://github.com/github/spec-kit.git" + $(if ($SpecKitRef) { "@$SpecKitRef" } else { "" })
  if (-not $SpecKitRef) { Write-Host "  note: no tag given; installing HEAD. Pin with -SpecKitRef vX.Y.Z (see releases)." }
  UvTool @("specify-cli", "--from", $src)
  Write-Host "  In a repo: specify init . --integration opencode --force   (claude | codex | cursor | gemini | copilot)"
}

if ($Compound) {
  Hr "compound-engineering (methodology plugin) — install inside the client"
  Write-Host "  Claude Code:  /plugin marketplace add EveryInc/compound-engineering-plugin ; /plugin install compound-engineering"
  Write-Host "  Codex:        codex plugin add compound-engineering@compound-engineering-plugin"
  Write-Host "  OpenCode:     add `"compound-engineering@git+https://github.com/EveryInc/compound-engineering-plugin.git#<sha>`" to `"plugin`""
  Write-Host "  Cursor:       /add-plugin compound-engineering"
  Write-Host "  Do not combine with superpowers / AI-DLC (one methodology pack)."
}

if ($Aidlc) {
  Hr "AI-DLC workflows (release installer, then per-project config)"
  $tmp = New-Item -ItemType Directory -Path (Join-Path ([IO.Path]::GetTempPath()) ("aidlc-" + [guid]::NewGuid()))
  $installer = Join-Path $tmp "install.ps1"
  Invoke-WebRequest -Uri "https://github.com/awslabs/aidlc-workflows/releases/latest/download/install.ps1" -OutFile $installer
  Write-Host "  installer sha256: $((Get-FileHash $installer -Algorithm SHA256).Hash.ToLower())"
  & $installer
  Remove-Item $tmp -Recurse -Force
  Write-Host "  In a project: aidlc config --harness opencode   (claude | codex | cursor | kiro | kiro-ide | copilot); aidlc doctor"
  Write-Host "  Then /aidlc <describe the work>. Diff AGENTS.md afterwards; it stays authoritative."
}

if ($Archify) {
  Hr "archify (validated diagrams; skill + Node renderer)"
  Need npx "install Node.js"
  npx -y skills add tt-a1i/archify -g -y
}

if ($Ponytail) {
  Hr "ponytail (always-on ruleset; plugin per client)"
  $cfgDir = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME ".config" }
  $cfg = Join-Path $cfgDir "opencode\opencode.json"
  if (Test-Path $cfg) {
    $d = Get-Content $cfg -Raw | ConvertFrom-Json -AsHashtable
    if (-not $d.ContainsKey("plugin")) { $d["plugin"] = @() }
    if (-not ($d["plugin"] | Where-Object { $_ -like "@dietrichgebert/ponytail*" })) {
      $d["plugin"] += "@dietrichgebert/ponytail"
      ($d | ConvertTo-Json -Depth 20) + "`n" | Set-Content $cfg -Encoding utf8NoBOM
      Write-Host "  added @dietrichgebert/ponytail to $cfg (pin a version, e.g. @dietrichgebert/ponytail@4.7.0)"
    } else { Write-Host "  already present in opencode.json" }
  } else { Write-Host "  OpenCode: add `"plugin`": [`"@dietrichgebert/ponytail`"] to $cfg" }
  Write-Host "  Claude Code: /plugin marketplace add DietrichGebert/ponytail  then  /plugin install ponytail@ponytail"
  Write-Host "  Codex:       codex plugin marketplace add DietrichGebert/ponytail; codex plugin add ponytail@ponytail"
  Write-Host "  Mode:        `$env:PONYTAIL_DEFAULT_MODE = 'full'   (lite|full|ultra|off)"
}

Write-Host "`ndone" -ForegroundColor Green
