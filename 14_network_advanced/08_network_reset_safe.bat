@echo off
call "%~dp0..\00_core\common.bat" >nul
call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5
choice /m "resetar winsock e tcp/ip agora?"
if errorlevel 2 exit /b 0
netsh winsock reset
netsh int ip reset "%nb_log%\ip_reset.log"
echo reinicio recomendado.
