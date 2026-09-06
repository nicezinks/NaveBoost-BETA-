@echo off
setlocal enableextensions
cd /d "%~dp0"
call "%~dp0..\00_core\common.bat" >nul
call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5
set /p "exe=digite o caminho completo do executavel: "
if not defined exe exit /b 2
if not exist "%exe%" (echo executavel nao encontrado.& exit /b 3)
for %%f in ("%exe%") do set "exe=%%~ff"
set "key=hkcu\software\microsoft\windows nt\currentversion\appcompatflags\layers"
reg add "%key%" /v "%exe%" /t reg_sz /d "~ disabledxmaximizedwindowedmode" /f
if errorlevel 1 (echo falha ao aplicar compatibilidade.& exit /b 4)
echo compatibilidade aplicada a: %exe%
echo para desfazer: reg delete "%key%" /v "%exe%" /f
exit /b 0
