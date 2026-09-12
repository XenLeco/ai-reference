# apiKeyHelper for Claude Code on Windows: print the gateway virtual key and nothing else.
# settings.json: "apiKeyHelper": "powershell -NoProfile -File C:\\Users\\<you>\\.claude\\get-gateway-key.ps1"
$ErrorActionPreference = "Stop"
if ($env:LITELLM_CLAUDE_CODE_KEY) {
  [Console]::Out.Write($env:LITELLM_CLAUDE_CODE_KEY)
  exit 0
}
$f = Join-Path $HOME ".config\ai-gateway\claude-code.key"
if (Test-Path $f) {
  [Console]::Out.Write((Get-Content $f -Raw).Trim())
  exit 0
}
[Console]::Error.WriteLine("no gateway key: set LITELLM_CLAUDE_CODE_KEY or create $f")
exit 1
