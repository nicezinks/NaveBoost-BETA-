@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5

echo this can improve responsiveness for some workloads but may increase power/heat.
reg import "%~dp0\01_pc_power_throttle_off.reg"
endlocal
