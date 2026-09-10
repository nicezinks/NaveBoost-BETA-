@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5

echo experimental profile. benchmark before/after.
reg import "%~dp0\02_pc_systemresponsiveness_10.reg"
reg import "%~dp0\08_pc_mmcss_games.reg"
endlocal
