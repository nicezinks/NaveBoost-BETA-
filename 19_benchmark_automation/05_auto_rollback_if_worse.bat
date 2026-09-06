@echo off
setlocal enableextensions
cd /d "%~dp0"
call "%~dp0..\00_core\common.bat" >nul
set "report=%nb_report%\compare_latest.txt"
if not exist "%report%" (echo relatorio compare_latest.txt nao encontrado. execute 03_compare_runs.bat primeiro.& endlocal & exit /b 2)
findstr /r /c:"decisao=rollback_recommended" "%report%" >nul
if errorlevel 1 (
  echo decisao nao indica rollback automatico. nenhuma mudanca foi desfeita.
  findstr /r /c:"decisao=" "%report%"
  endlocal & exit /b 0
)
echo rollback recomendado detectado. restaurando snapshot e plano anterior uma unica vez.
call "%~dp0..\21_adaptive_engine\03_restore_adaptive.bat"
set "rc=%errorlevel%"
echo rollback concluido com codigo %rc%.
endlocal & exit /b %rc%
