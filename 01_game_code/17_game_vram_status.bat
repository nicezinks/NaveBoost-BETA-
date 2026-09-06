@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "get-ciminstance win32_videocontroller | select name,@{n='vram_gb';e={[math]::round($_.adapterram/1gb,2)}} | format-table -auto"
endlocal
