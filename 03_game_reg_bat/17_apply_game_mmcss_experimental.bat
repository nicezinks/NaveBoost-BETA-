@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5

echo experimental: applying mmcss games profile. create backup first.
reg import "%~dp0\05_game_mmcs_systemresponsiveness.reg"
reg import "%~dp0\06_game_gpu_priority.reg"
reg import "%~dp0\07_game_game_priority.reg"
reg import "%~dp0\08_game_scheduling_category.reg"
endlocal
