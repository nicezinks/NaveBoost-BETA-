@echo off
setlocal EnableExtensions
call "%~dp0..\00_core\common.bat" >nul
set "seconds=%~1"
if not defined seconds set "seconds=30"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\00_core\naveboost_cli.ps1" -Action telemetry -TelemetrySeconds %seconds%
set "rc=%errorlevel%"
endlocal & exit /b %rc%