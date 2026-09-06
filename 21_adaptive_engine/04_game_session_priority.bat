@echo off
setlocal enableextensions
cd /d "%~dp0"
call "%~dp0..\00_core\common.bat" >nul
set /p "pn=nome do executavel sem .exe: "
if not defined pn exit /b 2
call "%~dp0..\00_core\game_session_apply.bat" "%pn%" "balanced"
exit /b %errorlevel%
