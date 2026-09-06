@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

echo === background cpu/ram audit ===
powershell -noprofile -command "get-process | where-object {$_.cpu -ne $null} | sort-object cpu -descending | select-object -first 15 name,id,@{n='cpu_s';e={[math]::round($_.cpu,1)}},ws | format-table -auto"
endlocal
