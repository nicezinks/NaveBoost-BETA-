@echo off
setlocal enableextensions enabledelayedexpansion
cd /d "%~dp0"
call "%~dp0..\00_core\common.bat" >nul
call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 endlocal & exit /b 5
set "rc=0"
call :restore_one "hkcu\software\microsoft\windows\currentversion\gamedvr" "%nb_snapshot%\hkcu_gamedvr.reg" "%nb_snapshot%\hkcu_gamedvr.missing"
if errorlevel 1 set "rc=1"
call :restore_one "hkcu\system\gameconfigstore" "%nb_snapshot%\hkcu_gameconfigstore.reg" "%nb_snapshot%\hkcu_gameconfigstore.missing"
if errorlevel 1 set "rc=1"
call :restore_one "hklm\system\currentcontrolset\control\prioritycontrol" "%nb_snapshot%\hklm_prioritycontrol.reg" "%nb_snapshot%\hklm_prioritycontrol.missing"
if errorlevel 1 set "rc=1"
call :restore_one "hklm\software\microsoft\windows nt\currentversion\multimedia\systemprofile" "%nb_snapshot%\hklm_systemprofile.reg" "%nb_snapshot%\hklm_systemprofile.missing"
if errorlevel 1 set "rc=1"
if "%rc%"=="0" echo registry rollback ok
endlocal & exit /b %rc%

:restore_one
set "key=%~1"
set "regfile=%~2"
set "missing=%~3"
if exist "%regfile%" (
  reg import "%regfile%" >nul 2>&1
  if errorlevel 1 exit /b 1
  exit /b 0
)
if exist "%missing%" (
  reg delete "%key%" /f >nul 2>&1
  if errorlevel 1 (
    reg query "%key%" >nul 2>&1
    if not errorlevel 1 exit /b 1
  )
  exit /b 0
)
exit /b 0
