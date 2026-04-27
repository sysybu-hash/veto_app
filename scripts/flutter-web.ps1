# Flutter Web on Windows: avoid spaces in the project path (objective_c native_assets hook bug).
# Run:  powershell -ExecutionPolicy Bypass -File "C:\...\VETO App\scripts\flutter-web.ps1"
# Uses drive V: via subst; if V: is taken, edit $drive below.

$ErrorActionPreference = "Stop"
$drive = "V"
$projectRoot = Split-Path $PSScriptRoot -Parent

$frontend = Join-Path $projectRoot "frontend\pubspec.yaml"
if (-not (Test-Path $frontend)) {
  Write-Error "Expected: $frontend"
}

$mapped = (subst) 2>$null | Where-Object { $_ -match "^${drive}:\\" }
if (-not $mapped) {
  subst "${drive}:" $projectRoot
}

$flutterBat = Join-Path $projectRoot "flutter\bin\flutter.bat"
$flutterExe = if (Test-Path $flutterBat) { $flutterBat } else { "flutter" }

Set-Location "${drive}:\frontend"
$define = "--dart-define=VETO_API_BASE=https://veto-legal.onrender.com"
& $flutterExe run -d chrome $define @args
