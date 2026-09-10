@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "while($true){clear-host; get-process | sort ws -descending | select -first 15 name,id,ws,cpu,priorityclass | format-table -auto; start-sleep 2}"
endlocal
