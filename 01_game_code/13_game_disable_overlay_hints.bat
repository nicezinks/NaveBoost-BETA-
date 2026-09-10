@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

echo this module does not blindly disable overlays.
echo use the overlay audit in 14_game_overlay_audit.bat and choose per game.
endlocal
