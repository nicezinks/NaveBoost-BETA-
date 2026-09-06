@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

echo windows memory cache is managed by the os. no third-party ram cleaner is run here.
powershell -noprofile -command "get-ciminstance win32_operatingsystem | select freephysicalmemory,totalvisiblememorysize | format-list"
endlocal
