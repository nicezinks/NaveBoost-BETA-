@echo off
setlocal enableextensions enabledelayedexpansion
cd /d "%~dp0"
call "%~dp0..\00_core\common.bat" >nul
call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 endlocal & exit /b 5
call "%~dp0\01_hardware_profile.bat" >nul
if errorlevel 1 (echo falha ao gerar perfil de hardware.& endlocal & exit /b 2)
set "profile=%nb_data%\state\hardware_profile.json"
for /f "delims=" %%a in ('powershell.exe -noprofile -command "$h=get-content -raw -literalpath '%profile%'|convertfrom-json; write-output $h.desktop"') do set "desktop=%%a"
for /f "delims=" %%a in ('powershell.exe -noprofile -command "$h=get-content -raw -literalpath '%profile%'|convertfrom-json; write-output $h.ramgb"') do set "ramgb=%%a"
for /f "delims=" %%a in ('powershell.exe -noprofile -command "$h=get-content -raw -literalpath '%profile%'|convertfrom-json; write-output $h.logical"') do set "logical=%%a"
if not defined desktop set "desktop=false"
if not defined ramgb set "ramgb=0"
if not defined logical set "logical=0"
call "%~dp0..\10_backup_rollback\09_snapshot_all.bat"
if errorlevel 1 (echo snapshot apresentou erro; nenhuma alteracao sera feita.& endlocal & exit /b 3)
>"%nb_snapshot%\adaptive_previous_scheme.txt" type nul
for /f "tokens=4" %%g in ('powercfg /getactivescheme') do echo %%g>"%nb_snapshot%\adaptive_previous_scheme.txt"
if /i "%desktop%"=="true" (
  choice /m "desktop detectado. ativar plano alto desempenho durante jogos"
  if not errorlevel 2 (
    powercfg /setactive scheme_min
    if errorlevel 1 echo nao foi possivel ativar high performance; mantendo plano atual.
  )
) else echo notebook/bateria detectado: mantendo plano de energia atual.
choice /m "aplicar perfil base seguro (game mode + captura em segundo plano off)"
if errorlevel 2 (echo nenhuma alteracao de registro aplicada.& endlocal & exit /b 0)
call "%~dp0..\00_core\apply_reg.bat" "%~dp0safe_gaming_base.reg"
if errorlevel 1 (echo perfil base nao aplicado.& endlocal & exit /b 4)
echo perfil adaptativo seguro concluido. tweaks experimentais ficam fora do caminho padrao.
endlocal & exit /b 0
