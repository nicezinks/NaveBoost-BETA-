@echo off
setlocal enableextensions
cd /d "%~dp0"
call "%~dp0..\00_core\common.bat" >nul
call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5
echo perfil adaptativo reversivel: snapshot + deteccao de hardware + ajustes seletivos.
call "%~dp0..\21_adaptive_engine\02_safe_adaptive_apply.bat"
exit /b %errorlevel%
