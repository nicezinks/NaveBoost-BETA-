@echo off
setlocal enableextensions
cd /d "%~dp0"
title naveboost turbo pro 7.5 adaptive - pubg
echo perfil pubg competitivo.
echo recurso: prioridade temporaria abovenormal + priorityboost, sem injecao ou patch.
call "%~dp0..\00_core\game_session_apply.bat" "tslgame.exe" "competitive"
set "rc=%errorlevel%"
echo.
if "%rc%"=="0" echo ok: ajuste de sessao aplicado ao processo em execucao.
if not "%rc%"=="0" echo falha/ausencia do processo. codigo=%rc%
pause
exit /b %rc%
