@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

echo === verify game settings ===
reg query "hkcu\software\microsoft\windows\currentversion\gamedvr"
reg query "hkcu\system\gameconfigstore"
reg query "hklm\software\microsoft\windows nt\currentversion\multimedia\systemprofile\tasks\games"
endlocal
