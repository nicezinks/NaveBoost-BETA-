@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

set /p "pn=game process name: "
powershell -noprofile -command "get-process -name '%pn%' -erroraction silentlycontinue | select name,id,cpu,ws,priorityclass | format-list"
endlocal
