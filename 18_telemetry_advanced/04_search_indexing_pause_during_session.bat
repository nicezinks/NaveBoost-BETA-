@echo off
call "%~dp0..\00_core\common.bat" >nul
call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5
sc query wsearch
choice /m "parar temporariamente o windows search?"
if errorlevel 2 exit /b 0
net stop wsearch
if errorlevel 1 (echo falha ao parar wsearch.& exit /b 3)
echo para restaurar: net start wsearch
