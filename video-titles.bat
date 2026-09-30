@echo off
setlocal
if "%~1"=="" (
    echo Usage: video-titles ^<video_file^>
    exit /b 1
)
bun --no-env-file run "%~dp0index.ts" %*
exit /b %errorlevel%
