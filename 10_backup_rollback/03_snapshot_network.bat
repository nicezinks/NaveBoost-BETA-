@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

netsh interface show interface > ..\data\snapshots\network_interfaces.txt
ipconfig /all > ..\data\snapshots\ipconfig.txt
netsh winsock show catalog > ..\data\snapshots\winsock_catalog.txt
endlocal
