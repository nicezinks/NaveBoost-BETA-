@echo off
setlocal enableextensions
cd /d "%~dp0"
:menu
cls
echo ================================================================
echo             naveboost profile wizard 7.5 adaptive
 echo ================================================================
echo [1] detectar hardware
 echo [2] perfil seguro
 echo [3] perfil adaptativo
 echo [4] benchmark completo + decisao
 echo [5] exportar relatorio de sessao
 echo [0] voltar
set /p "c=selecione: "
if "%c%"=="1" ( call "%~dp0\01_hardware_class_detect.bat" & pause & goto menu )
if "%c%"=="2" ( call "%~dp0\02_safe_profile_apply.bat" & pause & goto menu )
if "%c%"=="3" ( call "%~dp0\03_aggressive_profile_apply.bat" & pause & goto menu )
if "%c%"=="4" ( call "%~dp0\04_one_click_benchmark_and_decide.bat" & pause & goto menu )
if "%c%"=="5" ( call "%~dp0\05_session_report_export.bat" & pause & goto menu )
if "%c%"=="0" exit /b 0
goto menu
