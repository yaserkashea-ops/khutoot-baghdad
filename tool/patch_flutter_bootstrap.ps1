# Patches Flutter's generated bootstrap so it does not register
# flutter_service_worker.js (which pins old main.dart.js on devices).
$bootstrap = Join-Path $PSScriptRoot "..\build\web\flutter_bootstrap.js"
if (-not (Test-Path $bootstrap)) {
  Write-Error "Missing $bootstrap — run flutter build web first."
  exit 1
}
$text = Get-Content -Path $bootstrap -Raw -Encoding UTF8
$patched = [regex]::Replace(
  $text,
  '_flutter\.loader\.load\(\{[\s\S]*?\}\);',
  '_flutter.loader.load({});'
)
if ($patched -eq $text) {
  Write-Host "flutter_bootstrap.js: no loader block matched (already patched?)"
} else {
  Set-Content -Path $bootstrap -Value $patched -Encoding UTF8 -NoNewline
  Write-Host "flutter_bootstrap.js: disabled Flutter service worker"
}
