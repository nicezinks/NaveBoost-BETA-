@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

systeminfo > "%log%\systeminfo.txt" & powercfg /getactivescheme >> "%log%\systeminfo.txt" & ipconfig /all >> "%log%\systeminfo.txt" & tasklist >> "%log%\systeminfo.txt"
endlocal
