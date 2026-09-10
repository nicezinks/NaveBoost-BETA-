@echo off
setlocal enableextensions
cd /d "%~dp0.."
call "%~dp0common.bat" >nul
title naveboost turbo pro %nb_version% - pack validator
powershell.exe -noprofile -executionpolicy bypass -file "%~dp0verify_pack.ps1"
set "rc=%errorlevel%"
echo.
if not "%rc%"=="0" echo validacao falhou. veja o relatorio em data\reports\pack_validation.txt
if "%rc%"=="0" echo validacao ok. pack sem referencias quebradas detectadas pelo validador estatico.
pause
endlocal & exit /b %rc%
