@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

echo services commonly related to gaming features:
sc query bits | findstr state
sc query sysmain | findstr state
sc query xboxgipsvc | findstr state
endlocal
