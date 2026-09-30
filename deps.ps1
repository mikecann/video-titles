# deps.ps1 - install dependencies for video-titles

if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
    Write-Host "  [WARN] bun is not installed." -ForegroundColor Yellow
    Write-Host "         Install it with:  winget install oven-sh.bun" -ForegroundColor Yellow
    throw 'Bun is required. Install it with: winget install oven-sh.bun'
}

Write-Host "  [bun]  Installing video-titles dependencies..." -ForegroundColor DarkGray
Push-Location $PSScriptRoot
try {
    bun install --frozen-lockfile
    if ($LASTEXITCODE -ne 0) { throw "bun install failed with exit code $LASTEXITCODE" }
} finally {
    Pop-Location
}
Write-Host "  [ok]   video-titles dependencies ready." -ForegroundColor Green
