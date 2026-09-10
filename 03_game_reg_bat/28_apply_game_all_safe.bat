@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5

call "%~dp0\19_backup_game_keys.bat"
call "%~dp0\16_apply_game_safe.bat"
call "%~dp0\21_apply_game_audio_capture_off.bat"
endlocal
