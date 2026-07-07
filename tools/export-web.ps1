$ErrorActionPreference = "Stop"
$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$godot = "C:\Users\maxar\godot-editor\Godot_v4.7-stable_win64_console.exe"

New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot "builds\web") | Out-Null

& $godot --headless --export-release "Web" "builds/web/index.html"

Copy-Item (Join-Path $projectRoot "data\quiz.json") (Join-Path $projectRoot "builds\web\quiz.json") -Force

$photoPath = Join-Path $projectRoot "data\photo.jpg"
if (Test-Path $photoPath) {
    Copy-Item $photoPath (Join-Path $projectRoot "builds\web\photo.jpg") -Force
} else {
    Write-Warning "data/photo.jpg not found - the game will run without a photo until you add one."
}

Write-Host "Exported to builds/web with data files copied. Preview with tools/serve.ps1."
