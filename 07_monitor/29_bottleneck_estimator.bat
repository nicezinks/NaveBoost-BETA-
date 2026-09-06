@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "$cpu=(get-counter '\processor(_total)\% processor time').countersamples.cookedvalue; [pscustomobject]@{cpu=[math]::round($cpu,1);hint=$(if($cpu -gt 90){'cpu-bound likely'}else{'need gpu/frametime data'})} | format-list"
endlocal
