$ErrorActionPreference = "Stop"
$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$godot = "C:\Users\maxar\godot-editor\Godot_v4.7-stable_win64_console.exe"

New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot "builds\web") | Out-Null

& $godot --headless --export-release "Web" "builds/web/index.html"

$webDir = Join-Path $projectRoot "builds\web"
Get-ChildItem (Join-Path $projectRoot "data") -File | Where-Object { $_.Name -ne ".gdignore" } | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $webDir $_.Name) -Force
}

Write-Host "Exported to builds/web with data files copied. Preview with tools/serve.ps1."
