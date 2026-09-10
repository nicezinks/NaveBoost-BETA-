@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5

if exist "..\data\snapshots\prioritycontrol.reg" reg import "..\data\snapshots\prioritycontrol.reg"
if exist "..\data\snapshots\systemprofile.reg" reg import "..\data\snapshots\systemprofile.reg"
if exist "..\data\snapshots\powerthrottling.reg" reg import "..\data\snapshots\powerthrottling.reg"
endlocal
