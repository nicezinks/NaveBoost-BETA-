@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

echo removing only current-user temporary files older than 3 days.
forfiles /p "%temp%" /s /m * /d -3 /c "cmd /c del /q @path" 2>nul
endlocal
