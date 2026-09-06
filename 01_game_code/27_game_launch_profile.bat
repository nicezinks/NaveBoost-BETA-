@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5

set /p "profile=profile file path: "
if not exist "%profile%" exit /b 2
call "%profile%"
if not defined game_exe exit /b 3
start "game" /high "%game_exe%"
endlocal
