@echo off
setlocal enableextensions
fltmc >nul 2>&1
if not errorlevel 1 exit /b 0
echo [admin] este recurso precisa de privilegios de administrador.
echo [admin] execute start_here.bat usando "executar como administrador" e tente novamente.
exit /b 5
