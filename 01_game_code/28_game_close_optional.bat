@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

echo showing optional background apps; nothing is killed automatically.
powershell -noprofile -command "get-process | where-object {$_.mainwindowtitle} | select name,id,mainwindowtitle | format-table -auto"
endlocal
