param(
  [string]$Date = (Get-Date -Format "yyyy-MM-dd"),
  [int]$Limit = 160,
  [int]$Port = 5555,
  [switch]$NoServe
)

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $root

py -3 -m dailynews_backend.local_snapshot `
  --date $Date `
  --limit $Limit `
  --output "web/news_snapshot.json"

if (-not $NoServe) {
  & (Join-Path $PSScriptRoot "serve_web.ps1") -Port $Port
  Write-Host "Updated snapshot for $Date and serving at http://127.0.0.1:$Port"
} else {
  Write-Host "Updated snapshot for $Date. Serving skipped."
}
