@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "get-winevent -filterhashtable @{logname='system';level=2;starttime=(get-date).addhours(-24)} -maxevents 50 | select timecreated,providername,id,message | format-list"
endlocal
