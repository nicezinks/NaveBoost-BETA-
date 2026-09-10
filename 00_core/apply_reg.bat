@echo off
setlocal enableextensions
set "regfile=%~1"
if not defined regfile echo uso: apply_reg.bat arquivo.reg& exit /b 2
if not exist "%regfile%" echo reg nao encontrado: %regfile%& exit /b 3
cd /d "%~dp0"
call "%~dp0common.bat" >nul
call "%~dp0require_admin.bat"
if errorlevel 5 exit /b 5
set "stamp=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "stamp=%stamp: =0%"
set "backup=%nb_snapshot%\pre_reg_%stamp%.reg"
set "logfile=%nb_log%\last_reg_apply.log"
powershell.exe -noprofile -executionpolicy bypass -file "%~dp0export_reg_key_from_file.ps1" -regfile "%regfile%" -backupfile "%backup%" >"%logfile%" 2>&1
if errorlevel 1 (>>"%logfile%" echo result=backup_failed& echo backup da chave alvo falhou. import abortado.& exit /b 6)
>>"%logfile%" echo file=%regfile%
reg import "%regfile%" >>"%logfile%" 2>&1
if errorlevel 1 (>>"%logfile%" echo result=import_failed& echo falha no import. veja %logfile%& exit /b 7)
>>"%logfile%" echo result=ok
>>"%logfile%" echo backup=%backup%
echo reg aplicado com backup: %backup%
exit /b 0
