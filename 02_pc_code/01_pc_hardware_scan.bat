@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "get-ciminstance win32_processor | format-list name,numberofcores,numberoflogicalprocessors,maxclockspeed; get-ciminstance win32_physicalmemory | measure-object capacity -sum | foreach-object {'ram gb: '+[math]::round($_.sum/1gb,2)}; get-ciminstance win32_videocontroller | format-list name,driverversion,adapterram"
endlocal
