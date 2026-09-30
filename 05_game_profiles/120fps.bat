@echo off
setlocal EnableExtensions
cd /d "%~dp0"
call "%~dp0auto_game.bat" "fps120"
set "rc=%errorlevel%"
exit /b %rc%
