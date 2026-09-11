# Patches Flutter's generated bootstrap so it does not register
# flutter_service_worker.js (which pins old main.dart.js on devices).
$bootstrap = Join-Path $PSScriptRoot "..\build\web\flutter_bootstrap.js"
if (-not (Test-Path $bootstrap)) {
  Write-Error "Missing $bootstrap — run flutter build web first."
  exit 1
}
$path = (Resolve-Path $bootstrap).Path
$text = [IO.File]::ReadAllText($path)
$pattern = '(?s)_flutter\.loader\.load\(\{\s*serviceWorkerSettings:[\s\S]*?\}\);'
$patched = [regex]::Replace($text, $pattern, '_flutter.loader.load({});')
if ($patched -eq $text) {
  $patched = [regex]::Replace(
    $text,
    '(?s)serviceWorkerSettings:\s*\{[^}]*\}',
    'serviceWorkerSettings: null'
  )
}
if ($patched -eq $text) {
  Write-Host "flutter_bootstrap.js: WARNING — could not disable Flutter SW"
  exit 1
}
[IO.File]::WriteAllText($path, $patched)
Write-Host "flutter_bootstrap.js: disabled Flutter service worker"
