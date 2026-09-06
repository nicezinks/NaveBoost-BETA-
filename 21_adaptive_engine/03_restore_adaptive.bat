@echo off
setlocal enableextensions
cd /d "%~dp0"
call "%~dp0..\00_core\common.bat" >nul
call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5
set "rc=0"
if exist "%nb_snapshot%\adaptive_previous_scheme.txt" (
  set /p "scheme="<"%nb_snapshot%\adaptive_previous_scheme.txt"
  if defined scheme powercfg /setactive %scheme%
)
call "%~dp0..\10_backup_rollback\11_rollback_registry.bat"
if errorlevel 1 set "rc=1"
echo restore concluido. verifique o plano ativo e o relatorio de rollback.
exit /b %rc%
