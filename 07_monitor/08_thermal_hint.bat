@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "try{get-ciminstance msacpi_thermalzonetemperature | select instancename,currenttemperature}catch{'sensor unavailable'}"
endlocal
