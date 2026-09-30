@echo off
setlocal EnableExtensions
cd /d "%~dp0"
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0autodebloat.ps1" -Restore
set "rc=%errorlevel%"
exit /b %rc%
