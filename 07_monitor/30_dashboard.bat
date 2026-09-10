@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "write-host "naveboost live dashboard"; get-ciminstance win32_operatingsystem | select @{n='ram_free_gb';e={[math]::round($_.freephysicalmemory/1mb,2)}}; get-counter '\processor(_total)\% processor time' | select -expand countersamples | select @{n='cpu';e={[math]::round($_.cookedvalue,1)}}"
endlocal
