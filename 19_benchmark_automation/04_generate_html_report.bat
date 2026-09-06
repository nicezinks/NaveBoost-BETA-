@echo off
call "%~dp0..\00_core\common.bat" >nul
set /p "r=arquivo txt do comparador: "
if not exist "%r%" (echo relatorio nao encontrado.& exit /b 2)
set "out=%nb_report%\benchmark_%random%.html"
powershell.exe -noprofile -executionpolicy bypass -file "%~dp0\04_generate_html_report.ps1" -textreport "%r%" -output "%out%"
if errorlevel 1 exit /b 3
echo %out%
start "" "%out%"
