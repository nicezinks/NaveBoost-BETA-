@echo off
setlocal enableextensions enabledelayedexpansion
call "%~dp0..\00_core\common.bat" >nul
call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 endlocal & exit /b 5
for /f "tokens=4" %%g in ('powercfg /getactivescheme') do set "scheme=%%g"
if not defined scheme (echo plano ativo nao detectado.& endlocal & exit /b 2)
if not exist "%nb_snapshot%\cpu_core_parking_backup.txt" (
  for /f "tokens=4" %%a in ('powercfg /query %scheme% sub_processor cpmincores ^| findstr /i "current ac power setting index"') do >"%nb_snapshot%\cpu_core_parking_backup.txt" echo ac=%%a
  for /f "tokens=4" %%a in ('powercfg /query %scheme% sub_processor cpmincores ^| findstr /i "current dc power setting index"') do >>"%nb_snapshot%\cpu_core_parking_backup.txt" echo dc=%%a
  >"%nb_snapshot%\cpu_core_parking_scheme.txt" echo %scheme%
)
choice /m "aplicar core parking minimo 100%% somente na tomada (ac)"
if errorlevel 2 (echo operacao cancelada.& endlocal & exit /b 0)
powercfg /setacvalueindex %scheme% sub_processor cpmincores 100
if errorlevel 1 (echo falha ao alterar core parking.& endlocal & exit /b 3)
powercfg /setactive %scheme% >nul 2>&1
echo core parking ac configurado para minimo de 100%%. bateria/dc nao foi alterada.
endlocal & exit /b 0
