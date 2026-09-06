@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "while($true){get-netadapterstatistics | format-table name,receivedbytes,sentbytes -auto; start-sleep 2}"
endlocal
