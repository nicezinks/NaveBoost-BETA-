@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "get-volume | where driveletter | select driveletter,filesystemlabel,@{n='freegb';e={[math]::round($_.sizeremaining/1gb,1)}},@{n='sizegb';e={[math]::round($_.size/1gb,1)}} | format-table -auto"
endlocal
