@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5

if not exist "..\data\snapshots" mkdir "..\data\snapshots"
reg export "hklm\system\currentcontrolset\control\prioritycontrol" "..\data\snapshots\prioritycontrol.reg" /y
reg export "hklm\software\microsoft\windows nt\currentversion\multimedia\systemprofile" "..\data\snapshots\systemprofile.reg" /y
reg export "hklm\system\currentcontrolset\control\power\powerthrottling" "..\data\snapshots\powerthrottling.reg" /y
endlocal
