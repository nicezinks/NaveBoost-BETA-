@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5

set /p "game=enter full path to game exe: "
if not exist "%game%" exit /b 2
powershell -noprofile -command "$p=start-process -filepath '%game%' -passthru; start-sleep -milliseconds 800; $p.priorityclass='high'; 'applied high priority to pid '+$p.id"
endlocal
