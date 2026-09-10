@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5

set /p "pn=process name: "
powershell -noprofile -command "$p=get-process -name '%pn%' -erroraction silentlycontinue; if($p){$p.processoraffinity=[intptr]::new(-1); 'reset affinity for '+$p.id}else{'process not found'}"
endlocal
