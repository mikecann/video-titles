# Remove only this tool; leave the shared menu, other verbs and PATH alone.
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'This uninstaller is for Windows.' }
. (Join-Path $PSScriptRoot 'install-lib.ps1')
$ToolsDir = 'C:\dev\tools'
$batPath = Join-Path $ToolsDir 'video-titles.bat'
if (Test-Path -LiteralPath $batPath) {
    if ((Get-Content -LiteralPath $batPath -Raw).Trim() -ne (Get-BatStubContent $PSScriptRoot).Trim()) {
        Write-Host 'The installed launcher belongs to another clone or was edited. Leaving it in place.' -ForegroundColor Yellow
        return
    }
}

$keepIcon = $false
foreach ($ext in Get-VideoExtensions) {
    $verbKey = "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\MikesTools\shell\VideoTitles"
    $cmdKey = "$verbKey\command"
    if (Test-Path $cmdKey) {
        $command = (Get-Item $cmdKey).GetValue('')
        if ($command -eq (Get-VideoTitlesCommand $ToolsDir)) {
            Remove-Item -Path $verbKey -Recurse -Force
        }
    }
    if (Test-Path $verbKey) { $keepIcon = $true }
}
if (Test-Path -LiteralPath $batPath) { Remove-Item -LiteralPath $batPath }
$bashPath = Join-Path $ToolsDir 'video-titles'
if (Test-Path -LiteralPath $bashPath) {
    if ((Get-Content -LiteralPath $bashPath -Raw).Trim() -eq (Get-BashStubContent).Trim()) {
        Remove-Item -LiteralPath $bashPath
    }
}
$icon = Join-Path $env:LOCALAPPDATA 'video-titles\icons\video-titles.ico'
if (-not $keepIcon -and (Test-Path -LiteralPath $icon)) { Remove-Item -LiteralPath $icon }
Write-Host 'Removed video-titles. The shared menu, PATH and this clone are unchanged.' -ForegroundColor Green
