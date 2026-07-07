param(
    [int]$Port = 8060,
    [string]$Root = (Join-Path $PSScriptRoot "..\builds\web")
)

$Root = (Resolve-Path $Root).Path
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Serving $Root on http://localhost:$Port/"

$mime = @{
    ".html" = "text/html"
    ".js"   = "application/javascript"
    ".wasm" = "application/wasm"
    ".pck"  = "application/octet-stream"
    ".png"  = "image/png"
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
        $filePath = Join-Path $Root ($path.TrimStart("/"))
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
