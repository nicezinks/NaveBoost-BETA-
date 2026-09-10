@echo off
setlocal enableextensions
call "%~dp0common.bat" >nul
set "pn=%~1"
set "mode=%~2"
if not defined pn set /p "pn=[PROCESSO/APLICACAO] nome com ou sem .exe; caminho completo com .exe: "
if not defined mode set "mode=balanced"
if not defined pn echo nome do executavel obrigatorio.& exit /b 2
powershell.exe -noprofile -executionpolicy bypass -file "%~dp0game_session_apply.ps1" -processname "%pn%" -mode "%mode%"
exit /b %errorlevel%
