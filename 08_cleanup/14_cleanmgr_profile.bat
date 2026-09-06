@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

cleanmgr /sageset:1
echo re-run with cleanmgr /sagerun:1 after selecting items.
endlocal
