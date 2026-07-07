$ErrorActionPreference = "Stop"
$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$godot = "C:\Users\maxar\godot-editor\Godot_v4.7-stable_win64_console.exe"

New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot "builds\web") | Out-Null

& $godot --headless --export-release "Web" "builds/web/index.html"

$webDir = Join-Path $projectRoot "builds\web"
$dataDir = Join-Path $projectRoot "data"
Get-ChildItem $dataDir -File -Recurse | Where-Object { $_.Name -ne ".gdignore" } | ForEach-Object {
    $relativePath = $_.FullName.Substring($dataDir.Length).TrimStart('\', '/')
    $destPath = Join-Path $webDir $relativePath
    New-Item -ItemType Directory -Force -Path (Split-Path $destPath -Parent) | Out-Null
    Copy-Item $_.FullName $destPath -Force
}

Write-Host "Exported to builds/web with data files copied. Preview with tools/serve.ps1."
