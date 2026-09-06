@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

set /p "label=snapshot label: "
echo %date% %time% - %label%>>..\data\snapshots\labels.txt
endlocal
