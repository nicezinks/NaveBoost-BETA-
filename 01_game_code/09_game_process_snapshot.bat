@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

echo === process snapshot ===
powershell -noprofile -command "get-process | select name,id,priorityclass,ws,cpu -erroraction silentlycontinue | sort ws -descending | export-csv '%log%\process_snapshot.csv' -notypeinformation"
echo saved to %log%\process_snapshot.csv
endlocal
