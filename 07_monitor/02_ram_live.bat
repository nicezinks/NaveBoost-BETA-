@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "while($true){$o=get-ciminstance win32_operatingsystem; $u=(1-$o.freephysicalmemory/$o.totalvisiblememorysize)*100; write-host ("ram {0:n1}%" -f $u); start-sleep 1}"
endlocal
