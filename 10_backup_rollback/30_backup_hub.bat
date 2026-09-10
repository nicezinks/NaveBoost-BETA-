@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5

echo [1] snapshot all [2] list [3] verify [4] rollback registry [5] recovery
choice /c 12345 /n
if errorlevel 5 call "%~dp0\29_recovery_mode.bat"
if errorlevel 4 call "%~dp0\11_rollback_registry.bat"
if errorlevel 3 call "%~dp0\22_verify_snapshot_integrity.bat"
if errorlevel 2 call "%~dp0\10_list_snapshots.bat"
if errorlevel 1 call "%~dp0\09_snapshot_all.bat"
endlocal
