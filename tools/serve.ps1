param(
    [int]$Port = 8060,
    [string]$Root = (Join-Path $PSScriptRoot "..\builds\web"),
    [string]$DataRoot = (Join-Path $PSScriptRoot "..\data")
)

$Root = (Resolve-Path $Root).Path
$DataRoot = (Resolve-Path $DataRoot).Path
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Serving $Root on http://localhost:$Port/ (data/ files served live from $DataRoot)"

$mime = @{
    ".html" = "text/html"
    ".js"   = "application/javascript"
    ".wasm" = "application/wasm"
    ".pck"  = "application/octet-stream"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".svg"  = "image/svg+xml"
    ".json" = "application/json"
}

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $req = $context.Request
    $res = $context.Response
    try {
        $path = $req.Url.LocalPath
        if ($path -eq "/") { $path = "/index.html" }
        $relativePath = $path.TrimStart("/")
        $dataFilePath = Join-Path $DataRoot $relativePath
        $filePath = if (($relativePath -ne "") -and (Test-Path $dataFilePath -PathType Leaf)) {
            $dataFilePath
        } else {
            Join-Path $Root $relativePath
        }
        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath)
            $contentType = $mime[$ext]
            if (-not $contentType) { $contentType = "application/octet-stream" }
            $res.ContentType = $contentType
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $res.ContentLength64 = $bytes.Length
            $res.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $res.StatusCode = 404
        }
    } finally {
        $res.OutputStream.Close()
    }
}
