@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "get-itemproperty 'hkcu:\software\microsoft\windows\currentversion\gamedvr' -erroraction silentlycontinue | format-list appcaptureenabled; get-itemproperty 'hkcu:\system\gameconfigstore' -erroraction silentlycontinue | format-list gamedvr_enabled"
endlocal
