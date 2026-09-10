@echo off
setlocal enableextensions
cd /d "%~dp0"
call "%~dp0..\00_core\common.bat" >nul
echo ================================================================
echo one-click safe flow
 echo snapshot -> baseline -> ajuste seguro -> post -> compare
echo ================================================================
call "%~dp0..\10_backup_rollback\09_snapshot_all.bat"
if errorlevel 1 exit /b 3
call "%~dp0..\19_benchmark_automation\01_baseline_capture.bat"
if errorlevel 1 exit /b 4
echo.
echo agora aplique apenas um ajuste seguro ou use um perfil em 05_game_profiles.
pause
call "%~dp0..\19_benchmark_automation\02_post_change_capture.bat"
if errorlevel 1 exit /b 5
call "%~dp0..\19_benchmark_automation\03_compare_runs.bat"
if errorlevel 1 exit /b 6
call "%~dp0..\19_benchmark_automation\05_auto_rollback_if_worse.bat"
exit /b %errorlevel%
