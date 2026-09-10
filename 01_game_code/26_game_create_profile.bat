@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

set /p "name=profile name: "
set /p "exe=game exe full path: "
if not exist "profiles" mkdir profiles
>profiles\%name%.cmd echo set game_exe=%exe%
>>profiles\%name%.cmd echo rem add only reversible, tested actions here.
echo created profiles\%name%.cmd
endlocal
