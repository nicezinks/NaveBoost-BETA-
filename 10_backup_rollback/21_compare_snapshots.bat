@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "if(test-path ..\data\snapshots\drivers.csv){import-csv ..\data\snapshots\drivers.csv | measure-object}else{write-host 'no snapshot found'}"
endlocal
