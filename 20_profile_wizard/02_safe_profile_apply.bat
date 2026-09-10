@echo off
setlocal enableextensions
cd /d "%~dp0"
call "%~dp0..\00_core\common.bat" >nul
call "%~dp0..\21_adaptive_engine\02_safe_adaptive_apply.bat"
exit /b %errorlevel%
