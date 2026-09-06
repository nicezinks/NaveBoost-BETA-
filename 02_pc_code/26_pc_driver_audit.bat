@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "get-ciminstance win32_pnpsigneddriver | where {$_.devicename} | select devicename,driverversion,driverdate,manufacturer,issigned | export-csv '%log%\drivers.csv' -notypeinformation"
echo saved %log%\drivers.csv
endlocal
