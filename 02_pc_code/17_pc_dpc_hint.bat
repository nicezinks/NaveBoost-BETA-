@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

echo use the tools folder for a dedicated latency analyzer.
echo this script does not install kernel drivers or modify dpc settings.
endlocal
