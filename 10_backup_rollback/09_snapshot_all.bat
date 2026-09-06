@echo off
setlocal enableextensions enabledelayedexpansion
cd /d "%~dp0"
call "%~dp0..\00_core\common.bat" >nul
call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 endlocal & exit /b 5
set "rc=0"
for %%f in (01_snapshot_registry.bat 02_snapshot_power.bat 03_snapshot_network.bat 04_snapshot_process.bat 05_snapshot_services.bat 06_snapshot_startup.bat 07_snapshot_drivers.bat 08_snapshot_systeminfo.bat) do (
  call "%~dp0%%f"
  if errorlevel 1 (
    echo erro: %%f retornou codigo !errorlevel!.
    set "rc=1"
  )
)
if "%rc%"=="0" (echo snapshot completo concluido em %nb_snapshot%) else echo snapshot incompleto. alteracoes foram bloqueadas.
endlocal & exit /b %rc%
