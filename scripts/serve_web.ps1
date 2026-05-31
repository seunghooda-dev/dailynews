param(
  [int]$Port = 5555
)

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $root

$connections = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
foreach ($connection in $connections) {
  Stop-Process -Id $connection.OwningProcess -Force -ErrorAction SilentlyContinue
}

flutter build web --no-web-resources-cdn

$outLog = Join-Path $root "static_web.out.log"
$errLog = Join-Path $root "static_web.err.log"
foreach ($file in @($outLog, $errLog)) {
  if (Test-Path $file) {
    Remove-Item -LiteralPath $file -Force
  }
}

$python = (Get-Command py).Source
Start-Process `
  -FilePath $python `
  -ArgumentList @("-3", "-m", "http.server", "$Port", "--bind", "127.0.0.1", "-d", "build/web") `
  -WorkingDirectory $root `
  -WindowStyle Hidden `
  -RedirectStandardOutput $outLog `
  -RedirectStandardError $errLog

Write-Host "Serving Dailynews at http://127.0.0.1:$Port"
