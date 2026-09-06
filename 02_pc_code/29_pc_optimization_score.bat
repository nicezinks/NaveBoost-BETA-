@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "$o=get-ciminstance win32_operatingsystem; $free=[math]::round($o.freephysicalmemory/$o.totalvisiblememorysize*100,1); [pscustomobject]@{ramfreepct=$free;drivefreepct=(get-volume -driveletter c | foreach-object {[math]::round($_.sizeremaining/$_.size*100,1)});power=(powercfg /getactivescheme)} | format-list"
endlocal
