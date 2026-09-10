@echo off
setlocal EnableExtensions
cd /d "%~dp0.."
set "rc=0"
for %%T in ("%~dp0Test-*.ps1") do (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%%~fT"
  if errorlevel 1 set "rc=1"
)
if "%rc%"=="0" (echo PASS) else (echo FAIL)
endlocal & exit /b %rc%