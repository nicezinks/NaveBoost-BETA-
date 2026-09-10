@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

echo temp=%temp%
echo windowstemp=c:\windows\temp
for /f %%a in ('dir /s /a-d "%temp%" ^| find "file(s)"') do echo %%a
endlocal
