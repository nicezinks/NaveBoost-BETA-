@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

echo temp locations that can contain stale files:
echo %temp%
echo c:\windows\temp
dir "%temp%" /a 2>nul | findstr /r /c:"[0-9][0-9]* file"
endlocal
