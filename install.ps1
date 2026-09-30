# Install video-titles from this clone. No admin rights are required.
param([switch]$SkipDeps)

$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Use install.sh on macOS.' }
$RepoDir = $PSScriptRoot
$ToolsDir = 'C:\dev\tools'
. (Join-Path $RepoDir 'install-lib.ps1')

if (-not $SkipDeps) { & (Join-Path $RepoDir 'deps.ps1') }
if ($RepoDir -match '[^\x00-\x7F]') { throw 'Use an ASCII checkout path on Windows.' }
New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
Write-BatStub $RepoDir $ToolsDir
Write-Host "  [bat]  Installed video-titles into $ToolsDir" -ForegroundColor Green

$iconsOut = Join-Path $env:LOCALAPPDATA 'video-titles\icons'
New-Item -ItemType Directory -Path $iconsOut -Force | Out-Null
$titlesIco = Join-Path $iconsOut 'video-titles.ico'
ConvertTo-Ico (Join-Path $RepoDir 'icons\video-titles.png') $titlesIco
foreach ($ext in Get-VideoExtensions) {
    $root = "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\MikesTools"
    Set-MikesToolsRoot $root
    Add-VideoTitlesVerb $root $titlesIco (Get-VideoTitlesCommand $ToolsDir)
}
Write-Host "  [reg]  Added Mike's Tools > Video Titles for video files." -ForegroundColor Green

# Keep the shared tools directory on PATH even if this tool is later removed.
$machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
$userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
if (-not $userPath) { $userPath = '' }
$onPath = (($machinePath -split ';') + ($userPath -split ';')) |
    Where-Object { $_.TrimEnd('\') -ieq $ToolsDir.TrimEnd('\') }
if (-not $onPath) {
    $answer = Read-Host "Add $ToolsDir to your User PATH? [Y/n]"
    if ($answer -eq '' -or $answer -imatch '^y') {
        $newPath = ($userPath.TrimEnd(';') + ";$ToolsDir").TrimStart(';')
        [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        $env:PATH += ";$ToolsDir"
    }
}
Write-Host 'Done. Set OPENROUTER_API_KEY in .env, then open a new terminal.' -ForegroundColor Cyan
