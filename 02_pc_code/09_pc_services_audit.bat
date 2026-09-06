@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "get-ciminstance win32_service | where {$_.startmode -eq 'auto'} | sort displayname | select name,state,startmode,displayname | format-table -auto"
endlocal
