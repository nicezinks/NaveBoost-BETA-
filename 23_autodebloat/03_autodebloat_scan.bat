@echo off
setlocal EnableExtensions
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0autodebloat.ps1" -Scan
set "rc=%errorlevel%"
exit /b %rc%
