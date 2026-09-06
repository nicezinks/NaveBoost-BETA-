@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5

set /p "pn=process name: "
set /p "mask=affinity mask (hex, e.g. f): "
powershell -noprofile -command "$p=get-process -name '%pn%' -erroraction silentlycontinue; if($p){$p.processoraffinity=[intptr]::parse('%mask%', 'allowhexspecifier'); 'applied mask to '+$p.id}else{'process not found'}"
endlocal
