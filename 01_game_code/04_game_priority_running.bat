@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5

set /p "pn=process name (without .exe): "
powershell -noprofile -command "get-process -name '%pn%' -erroraction silentlycontinue | foreach-object { try { $_.priorityclass='high'; 'ok pid '+$_.id } catch { $_.exception.message } }"
endlocal
