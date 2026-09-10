@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "get-ciminstance win32_pnpsigneddriver | select devicename,driverversion,driverdate,manufacturer,issigned | export-csv ..\data\snapshots\drivers.csv -notypeinformation"
endlocal
