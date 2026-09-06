@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "get-ciminstance win32_process | select name,processid,parentprocessid,commandline | export-csv '%log%\process_tree.csv' -notypeinformation"
echo saved process tree.
endlocal
