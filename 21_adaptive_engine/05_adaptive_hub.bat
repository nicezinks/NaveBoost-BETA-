@echo off
setlocal enableextensions
cd /d "%~dp0"
:menu
cls
echo ================================================================
echo             naveboost - adaptive engine 7.2
 echo ================================================================
echo [1] detectar hardware
 echo [2] aplicar perfil base seguro
 echo [3] prioridade da sessao de jogo
 echo [4] restaurar perfil adaptativo
 echo [5] voltar
 echo ================================================================
set "c="
set /p "c=selecione: "
if "%c%"=="1" ( call "%~dp0\01_hardware_profile.bat" & pause & goto menu )
if "%c%"=="2" ( call "%~dp0\02_safe_adaptive_apply.bat" & pause & goto menu )
if "%c%"=="3" ( call "%~dp0\04_game_session_priority.bat" & pause & goto menu )
if "%c%"=="4" ( call "%~dp0\03_restore_adaptive.bat" & pause & goto menu )
if "%c%"=="5" exit /b 0
echo opcao invalida.& timeout /t 1 >nul
goto menu
