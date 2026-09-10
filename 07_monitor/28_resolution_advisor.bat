@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

echo compare fixed benchmark runs at 1920x1080, 1600x900, 1366x768 and 1280x720. keep the highest resolution meeting the target fps.
endlocal
