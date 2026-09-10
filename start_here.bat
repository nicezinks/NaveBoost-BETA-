@echo off
setlocal EnableExtensions
cd /d "%~dp0"
call "%~dp0main.bat" %*
set "rc=%errorlevel%"
endlocal & exit /b %rc%