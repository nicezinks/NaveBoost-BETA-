@echo off
setlocal enableextensions enabledelayedexpansion
call "%~dp0..\00_core\common.bat" >nul
call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 endlocal & exit /b 5
if not exist "%nb_snapshot%\cpu_core_parking_scheme.txt" (echo backup nao encontrado.& endlocal & exit /b 2)
set /p "scheme="<"%nb_snapshot%\cpu_core_parking_scheme.txt"
if not defined scheme (echo guid do plano ausente.& endlocal & exit /b 3)
for /f "tokens=1,* delims==" %%a in (%nb_snapshot%\cpu_core_parking_backup.txt) do (
  if /i "%%a"=="ac" powercfg /setacvalueindex %scheme% sub_processor cpmincores %%b >nul 2>&1
  if /i "%%a"=="dc" powercfg /setdcvalueindex %scheme% sub_processor cpmincores %%b >nul 2>&1
)
powercfg /setactive %scheme% >nul 2>&1
echo core parking restaurado.
endlocal & exit /b 0
