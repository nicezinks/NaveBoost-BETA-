@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "get-counter '\physicaldisk(_total)\disk bytes/sec' -sampleinterval 1 -maxsamples 5 | select -expandproperty countersamples | select timestamp,cookedvalue | format-table -auto"
endlocal
