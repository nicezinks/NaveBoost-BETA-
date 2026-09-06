@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

echo run your game benchmark 3 times with the same route/scene.
echo suggested metrics: fps average, 1%% low, 0.1%% low, frametime, stutter count.
endlocal
