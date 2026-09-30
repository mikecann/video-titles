# Cross-platform helper checks; no writes to PATH or the real Windows registry.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../install-lib.ps1')
$testDir = Join-Path ([System.IO.Path]::GetTempPath()) ('video-titles-ps-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $testDir | Out-Null
try {
    Write-BatStub 'C:\clones\video titles' $testDir
    $batPath = Join-Path $testDir 'video-titles.bat'
    $bat = Get-Content -LiteralPath $batPath -Raw
    if ($bat -notmatch 'bun --no-env-file run "C:\\clones\\video titles\\index.ts" %\*') { throw 'Stub must quote this clone and forward all arguments.' }
    if ($bat -notmatch 'exit /b %errorlevel%') { throw 'Stub must preserve Bun exit code.' }
    if (([System.IO.File]::ReadAllBytes($batPath) | Where-Object { $_ -gt 127 }).Count) { throw 'Batch stub is not ASCII.' }
    if ((Get-Content -LiteralPath (Join-Path $testDir 'video-titles') -Raw).Trim() -ne (Get-BashStubContent).Trim()) { throw 'Git Bash wrapper did not match.' }
    $icon = Join-Path $testDir 'video-titles.ico'
    $pngPath = Join-Path $PSScriptRoot '../icons/video-titles.png'
    ConvertTo-Ico $pngPath $icon
    $bytes = [System.IO.File]::ReadAllBytes($icon)
    $png = [System.IO.File]::ReadAllBytes($pngPath)
    if ([BitConverter]::ToUInt16($bytes, 2) -ne 1 -or [BitConverter]::ToUInt16($bytes, 4) -ne 1) { throw 'Invalid ICO header.' }
    if ([BitConverter]::ToUInt32($bytes, 18) -ne 22 -or $bytes.Length -ne $png.Length + 22) { throw 'Invalid PNG-in-ICO size or offset.' }
    if ([Convert]::ToBase64String($bytes[22..($bytes.Length - 1)]) -ne [Convert]::ToBase64String($png)) { throw 'Icon must preserve the PNG payload.' }
    if ((Get-VideoExtensions).Count -ne 14) { throw 'Installer must cover all original video extensions.' }
    if ((Get-VideoTitlesCommand $testDir) -ne ('cmd.exe /k ""' + (Join-Path $testDir 'video-titles.bat') + '" "%1""')) { throw 'Explorer command quoting changed.' }
    Write-Host 'Installer helper checks passed.'
} finally {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
