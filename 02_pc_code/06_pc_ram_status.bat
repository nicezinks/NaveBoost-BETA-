@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "$o=get-ciminstance win32_operatingsystem; [pscustomobject]@{totalgb=[math]::round($o.totalvisiblememorysize/1mb,2);freegb=[math]::round($o.freephysicalmemory/1mb,2);usedpct=[math]::round((1-$o.freephysicalmemory/$o.totalvisiblememorysize)*100,1)} | format-list"
endlocal
