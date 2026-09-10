@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

reg query "hkcu\software\microsoft\windows\currentversion\run" > ..\data\snapshots\hkcu_run.txt
reg query "hklm\software\microsoft\windows\currentversion\run" > ..\data\snapshots\hklm_run.txt
endlocal
