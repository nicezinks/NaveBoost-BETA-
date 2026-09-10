@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

set /p "game=enter full path to game exe: "
if not exist "%game%" (echo file not found.& exit /b 2)
echo selected: %game%
>game_target.txt echo %game%
endlocal
