@echo off
setlocal enableextensions
cd /d "%~dp0"
title naveboost turbo pro 7.3 - custom
echo perfil customizado: ajuste temporario e reversivel.
set /p "pn=executavel do jogo (sem .exe): "
if not defined pn exit /b 2
call "%~dp0..\00_core\game_session_apply.bat" "%pn%" "balanced"
set "rc=%errorlevel%"
pause
exit /b %rc%
