@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

reg query "hklm\software\microsoft\windows nt\currentversion\multimedia" /s > ..\data\snapshots\multimedia_policy.txt
endlocal
