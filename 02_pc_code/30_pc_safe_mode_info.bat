@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

echo safe diagnostic guidance:
echo 1. create snapshot before registry changes.
echo 2. apply one module at a time.
echo 3. benchmark before/after.
echo 4. roll back if stability drops.
endlocal
