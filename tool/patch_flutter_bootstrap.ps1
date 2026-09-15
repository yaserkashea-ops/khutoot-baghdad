# Patches Flutter's generated bootstrap:
# 1) disable flutter_service_worker.js
# 2) force local CanvasKit (never gstatic CDN — fails on many Iraqi networks)
# 3) drop empty build stubs
$ErrorActionPreference = 'Stop'
$bootstrap = Join-Path $PSScriptRoot '..\build\web\flutter_bootstrap.js'
$full = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($bootstrap)
if (-not (Test-Path -LiteralPath $full)) {
  Write-Error "Missing $full - run flutter build web first."
  exit 1
}
$text = [IO.File]::ReadAllText($full)

# Disable Flutter SW
$pattern = '(?s)_flutter\.loader\.load\(\{[\s\S]*?\}\);'
$replacement = '_flutter.loader.load({config:{canvasKitBaseUrl:"canvaskit/"}});'
$patched = [regex]::Replace($text, $pattern, $replacement, 1)
if ($patched -eq $text) {
  # Fallback: only strip serviceWorkerSettings then inject config
  $patched = [regex]::Replace(
    $text,
    '(?s)_flutter\.loader\.load\(\{\s*serviceWorkerSettings:[\s\S]*?\}\);',
    '_flutter.loader.load({config:{canvasKitBaseUrl:"canvaskit/"}});'
  )
}
if ($patched -eq $text) {
  $patched = [regex]::Replace(
    $text,
    '_flutter\.loader\.load\(\{\}\);',
    '_flutter.loader.load({config:{canvasKitBaseUrl:"canvaskit/"}});'
  )
}
if ($patched -eq $text -and $text -notmatch 'canvasKitBaseUrl') {
  Write-Host "flutter_bootstrap.js: WARNING - could not patch loader"
  exit 1
}

$patched = [regex]::Replace($patched, '("builds"\s*:\s*\[[^\]]*?),\{\}(\s*\])', '$1$2')
[IO.File]::WriteAllText($full, $patched)
Write-Host "flutter_bootstrap.js: local CanvasKit + no Flutter SW ($full)"
