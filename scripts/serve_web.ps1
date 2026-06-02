param(
  [int]$Port = 5555,
  [switch]$Clean
)

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $root

$connections = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
foreach ($connection in $connections) {
  Stop-Process -Id $connection.OwningProcess -Force -ErrorAction SilentlyContinue
}

if ($Clean) {
  flutter clean
}

flutter pub get
flutter build web --no-web-resources-cdn --pwa-strategy=none

$serviceWorkerPath = Join-Path $root "build/web/flutter_service_worker.js"
@"
self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    if ('caches' in self) {
      const keys = await caches.keys();
      await Promise.all(keys.map((key) => caches.delete(key)));
    }
    const clientsList = await self.clients.matchAll({
      type: 'window',
      includeUncontrolled: true,
    });
    await self.registration.unregister();
    for (const client of clientsList) {
      client.navigate(client.url);
    }
  })());
});
"@ | Set-Content -LiteralPath $serviceWorkerPath -Encoding UTF8

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
  -ArgumentList @("-3", "scripts/no_cache_server.py", "--port", "$Port", "--bind", "127.0.0.1", "--directory", "build/web") `
  -WorkingDirectory $root `
  -WindowStyle Hidden `
  -RedirectStandardOutput $outLog `
  -RedirectStandardError $errLog

Write-Host "Serving Dailynews at http://127.0.0.1:$Port"
