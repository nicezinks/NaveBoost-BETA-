@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "try{get-ciminstance msacpi_thermalzonetemperature | select instancename,@{n='c';e={[math]::round($_.currenttemperature/10-273.15,1)}} | format-table -auto}catch{'temperature sensor unavailable through this interface.'}"
endlocal
