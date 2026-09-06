@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5

reg import "%~dp0\05_pc_capture_off.reg"
reg import "%~dp0\06_pc_background_record_off.reg"
endlocal
