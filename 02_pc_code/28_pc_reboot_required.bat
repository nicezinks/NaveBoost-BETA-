@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

echo this is an informational check only.
reg query "hklm\software\microsoft\windows\currentversion\component based servicing\rebootpending" >nul 2>&1 && echo windows reports a pending reboot. || echo no cbs reboot pending detected.
endlocal
