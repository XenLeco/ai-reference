#Requires -Version 7
<#
.SYNOPSIS
  Back up the gateway's Postgres (keys, teams, spend logs) with pg_dump, keep the last N.
.EXAMPLE
  ./backup-db.ps1 -Dest ./backups -Keep 14
  Restore: docker compose exec -T db pg_restore -U litellm -d litellm --clean --if-exists < backups/<file>.dump
#>
param([string]$Dest = "./backups", [int]$Keep = 14)
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
New-Item -ItemType Directory -Force $Dest | Out-Null
$out = Join-Path $Dest ("litellm-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".dump")
# -T keeps docker from allocating a TTY so the binary dump stays intact
docker compose exec -T db pg_dump -U litellm -Fc litellm | Set-Content -Path $out -AsByteStream
Write-Host "wrote $out ($([math]::Round((Get-Item $out).Length / 1KB)) KB)"
Get-ChildItem $Dest -Filter "litellm-*.dump" | Sort-Object LastWriteTime -Descending | Select-Object -Skip $Keep | ForEach-Object { Remove-Item $_.FullName; Write-Host "removed $($_.Name)" }
Write-Host "kept $((Get-ChildItem $Dest -Filter 'litellm-*.dump').Count) backups in $Dest (backups/ is git-ignored)"
