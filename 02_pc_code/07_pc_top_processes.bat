@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "get-process | sort-object ws -descending | select -first 25 name,id,priorityclass,@{n='ram_mb';e={[math]::round($_.ws/1mb,1)}} | format-table -auto"
endlocal
