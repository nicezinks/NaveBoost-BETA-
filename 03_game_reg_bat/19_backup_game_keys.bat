@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5

if not exist "..\data\snapshots" mkdir "..\data\snapshots"
reg export "hkcu\software\microsoft\windows\currentversion\gamedvr" "..\data\snapshots\gamedvr.reg" /y
reg export "hkcu\system\gameconfigstore" "..\data\snapshots\gameconfigstore.reg" /y
reg export "hklm\software\microsoft\windows nt\currentversion\multimedia\systemprofile" "..\data\snapshots\systemprofile.reg" /y
endlocal
