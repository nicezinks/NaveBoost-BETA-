@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

for %%n in (gamebar.exe gamebarftserver.exe discord.exe steamwebhelper.exe nvidia share.exe radeonsoftware.exe obs64.exe) do tasklist /fi "imagename eq %%n" | find /i "%%n" >nul && echo running: %%n || echo not running: %%n
endlocal
