@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "get-counter '\processor(_total)\%% processor time' -sampleinterval 1 -maxsamples 10 | select -expandproperty countersamples | select timestamp,@{n='cpu';e={[math]::round($_.cookedvalue,1)}} | format-table -auto"
endlocal
