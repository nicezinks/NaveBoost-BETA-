@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

reg query "hklm\system\currentcontrolset\control\prioritycontrol"
reg query "hklm\software\microsoft\windows nt\currentversion\multimedia\systemprofile"
reg query "hklm\system\currentcontrolset\control\power\powerthrottling"
endlocal
