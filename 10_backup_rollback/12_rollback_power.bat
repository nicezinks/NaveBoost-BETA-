@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

echo power plans are restored manually from the saved files; do not invent a plan guid.
more ..\data\snapshots\power_active.txt
endlocal
