@echo off
call "%~dp0..\00_core\common.bat" >nul
echo fluxo recomendado: snapshot -^> baseline -^> uma mudanca -^> post -^> compare -^> manter/rollback.
call "%~dp0..\19_benchmark_automation\01_baseline_capture.bat"
if errorlevel 1 exit /b 3
echo aplique o ajuste escolhido agora, depois pressione uma tecla para continuar.
pause
call "%~dp0..\19_benchmark_automation\02_post_change_capture.bat"
if errorlevel 1 exit /b 4
echo use 03_compare_runs.bat para decidir com dados.
