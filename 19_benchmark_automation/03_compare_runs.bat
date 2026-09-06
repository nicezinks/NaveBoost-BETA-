@echo off
setlocal enableextensions
call "%~dp0..\00_core\common.bat" >nul
set "b="
set "p="
if exist "%nb_bench%\baseline_latest.txt" set /p "b="<"%nb_bench%\baseline_latest.txt"
if exist "%nb_bench%\post_latest.txt" set /p "p="<"%nb_bench%\post_latest.txt"
if not defined b set /p "b=csv baseline (caminho completo): "
if not defined p set /p "p=csv pos-mudanca (caminho completo): "
if not exist "%b%" (echo baseline nao encontrado: %b%& exit /b 2)
if not exist "%p%" (echo pos-mudanca nao encontrado: %p%& exit /b 3)
set "out=%nb_report%\compare_latest.txt"
powershell.exe -noprofile -executionpolicy bypass -file "%~dp0\03_compare_runs.ps1" -baseline "%b%" -post "%p%" > "%out%"
if errorlevel 1 (
  echo falha ao comparar. veja %out%
  exit /b 4
)
type "%out%"
echo.
echo relatorio: %out%
exit /b 0
