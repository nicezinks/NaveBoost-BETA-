@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "get-process | sort-object @{expression={try{$_.cpu}catch{0}}} -descending | select-object -first 20 name,id,priorityclass | format-table -auto"
endlocal
