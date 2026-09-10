@echo off
setlocal enableextensions enabledelayedexpansion
cd /d "%~dp0"
call "%~dp0..\00_core\common.bat" >nul
call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 endlocal & exit /b 5
set "rc=0"
call :snapshot_key "hkcu\software\microsoft\windows\currentversion\gamedvr" "%nb_snapshot%\hkcu_gamedvr.reg" "%nb_snapshot%\hkcu_gamedvr.missing"
if errorlevel 1 set "rc=1"
call :snapshot_key "hkcu\system\gameconfigstore" "%nb_snapshot%\hkcu_gameconfigstore.reg" "%nb_snapshot%\hkcu_gameconfigstore.missing"
if errorlevel 1 set "rc=1"
call :snapshot_key "hklm\system\currentcontrolset\control\prioritycontrol" "%nb_snapshot%\hklm_prioritycontrol.reg" "%nb_snapshot%\hklm_prioritycontrol.missing"
if errorlevel 1 set "rc=1"
call :snapshot_key "hklm\software\microsoft\windows nt\currentversion\multimedia\systemprofile" "%nb_snapshot%\hklm_systemprofile.reg" "%nb_snapshot%\hklm_systemprofile.missing"
if errorlevel 1 set "rc=1"
if "%rc%"=="0" (echo registry snapshot ok) else echo registry snapshot falhou. nenhuma alteracao segura deve prosseguir.
endlocal & exit /b %rc%

:snapshot_key
set "key=%~1"
set "out=%~2"
set "missing=%~3"
del /q "%out%" "%missing%" >nul 2>&1
reg query "%key%" >nul 2>&1
if errorlevel 1 (
  >"%missing%" echo absent
  exit /b 0
)
reg export "%key%" "%out%" /y >nul 2>&1
if errorlevel 1 exit /b 1
exit /b 0
