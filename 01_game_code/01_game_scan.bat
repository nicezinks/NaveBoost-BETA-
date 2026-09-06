@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

echo === game environment scan ===
powershell -noprofile -command "get-ciminstance win32_operatingsystem | select caption,version,buildnumber | format-list; get-ciminstance win32_processor | select name,numberofcores,numberoflogicalprocessors | format-list; get-ciminstance win32_videocontroller | select name,driverversion,adapterram | format-list"
endlocal
