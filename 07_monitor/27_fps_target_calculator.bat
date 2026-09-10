@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

set /p "target=target fps: "
powershell -noprofile -command "[pscustomobject]@{targetfps=%target%;framebudgetms=[math]::round(1000/%target%,3)} | format-list"
endlocal
