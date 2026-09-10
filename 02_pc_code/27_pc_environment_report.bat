@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

set "out=%log%\environment_report.txt"
(systeminfo & echo. & powercfg /getactivescheme & echo. & ipconfig /all) > "%out%"
echo saved %out%
endlocal
