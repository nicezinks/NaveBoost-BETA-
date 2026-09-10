@echo off
setlocal EnableExtensions
call "%~dp0..\00_core\common.bat" >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\00_core\naveboost_cli.ps1" -Action bottleneck
set "rc=%errorlevel%"
endlocal & exit /b %rc%
