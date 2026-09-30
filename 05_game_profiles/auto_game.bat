@echo off
setlocal EnableExtensions
cd /d "%~dp0"
set "mode=%~1"
if not defined mode set "mode=balanced"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\00_core\game_auto_apply.ps1" -Mode "%mode%"
set "rc=%errorlevel%"
if "%rc%"=="0" echo otimização aplicada ao jogo detectado.
if not "%rc%"=="0" echo nenhum jogo elegível foi detectado ou a otimização falhou.
exit /b %rc%
