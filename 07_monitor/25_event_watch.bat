@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "get-winevent -filterhashtable @{logname='system';starttime=(get-date).addminutes(-10)} -maxevents 30 | select timecreated,leveldisplayname,providername,id | format-table -auto"
endlocal
