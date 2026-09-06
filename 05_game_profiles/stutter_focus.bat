@echo off
setlocal enableextensions
cd /d "%~dp0"
title naveboost turbo pro 7.3 - stutter_focus
echo perfil focado em estabilidade de frametime.
echo recurso: prioridade temporaria abovenormal + priorityboost, sem injecao ou patch.
call "%~dp0..\00_core\game_session_apply.bat" "game.exe" "latency"
set "rc=%errorlevel%"
echo.
if "%rc%"=="0" echo ok: ajuste de sessao aplicado ao processo em execucao.
if not "%rc%"=="0" echo falha/ausencia do processo. codigo=%rc%
pause
exit /b %rc%
