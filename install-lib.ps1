# Small, shared helpers for this tool's installer and uninstaller.
function Get-VideoExtensions {
    return @('.mp4', '.mkv', '.avi', '.mov', '.wmv', '.webm', '.m4v', '.mpg', '.mpeg', '.ts', '.mts', '.m2ts', '.flv', '.f4v')
}

function Get-BatStubContent([string]$RepoDir) {
    return "@echo off`r`nbun --no-env-file run `"$RepoDir\index.ts`" %*`r`nexit /b %errorlevel%"
}

function Get-BashStubContent {
    return @'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/video-titles.bat" "$@"
'@
}

function Write-BatStub([string]$RepoDir, [string]$ToolsDir) {
    # ASCII batch files cannot represent a non-ASCII checkout path safely.
    if ($RepoDir -match '[^\x00-\x7F]') {
        throw 'Clone video-titles into a path containing only ASCII characters on Windows.'
    }
    Set-Content -LiteralPath (Join-Path $ToolsDir 'video-titles.bat') -Value (Get-BatStubContent $RepoDir) -Encoding ASCII
    Set-Content -LiteralPath (Join-Path $ToolsDir 'video-titles') -Value (Get-BashStubContent) -Encoding ASCII
}

# PNG-in-ICO preserves the existing icon's alpha channel without imaging libraries.
function ConvertTo-Ico([string]$PngPath, [string]$IcoPath) {
    $pngBytes = [System.IO.File]::ReadAllBytes($PngPath)
    $stream = [System.IO.FileStream]::new($IcoPath, [System.IO.FileMode]::Create)
    $writer = [System.IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]1)
        $writer.Write([byte]16); $writer.Write([byte]16); $writer.Write([byte]0)
        $writer.Write([byte]0); $writer.Write([uint16]1); $writer.Write([uint16]32)
        $writer.Write([uint32]$pngBytes.Length); $writer.Write([uint32]22)
        $writer.Write($pngBytes)
    } finally {
        $writer.Dispose()
        $stream.Dispose()
    }
}

function Get-VideoTitlesCommand([string]$ToolsDir) {
    return 'cmd.exe /k ""' + (Join-Path $ToolsDir 'video-titles.bat') + '" "%1""'
}

function Set-MikesToolsRoot([string]$RootKey) {
    if (-not (Test-Path $RootKey)) {
        New-Item -Path $RootKey -Force | Out-Null
        # A system icon remains valid when any individual tool is uninstalled.
        Set-ItemProperty -Path $RootKey -Name 'Icon' -Value '%SystemRoot%\System32\shell32.dll,0'
    }
    Set-ItemProperty -Path $RootKey -Name 'MUIVerb' -Value "Mike's Tools"
    Set-ItemProperty -Path $RootKey -Name 'SubCommands' -Value ''
}

function Add-VideoTitlesVerb([string]$RootKey, [string]$Icon, [string]$Command) {
    $verbKey = "$RootKey\shell\VideoTitles"
    $cmdKey = "$verbKey\command"
    New-Item -Path $verbKey -Force | Out-Null
    New-Item -Path $cmdKey -Force | Out-Null
    Set-ItemProperty -Path $verbKey -Name 'MUIVerb' -Value 'Video Titles'
    Set-ItemProperty -Path $verbKey -Name 'Icon' -Value $Icon
    Set-ItemProperty -Path $cmdKey -Name '(Default)' -Value $Command
}
