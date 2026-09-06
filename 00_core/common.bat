@echo off
set "nb_root=%~dp0.."
for %%i in ("%nb_root%") do set "nb_root=%%~fi"
set "nb_data=%nb_root%\data"
set "nb_log=%nb_data%\logs"
set "nb_snapshot=%nb_data%\snapshots"
set "nb_bench=%nb_data%\benchmarks"
set "nb_report=%nb_data%\reports"
set "nb_profile=%nb_data%\profiles"
set "nb_state=%nb_data%\state"
for %%d in ("%nb_log%" "%nb_snapshot%" "%nb_bench%" "%nb_report%" "%nb_profile%" "%nb_state%") do if not exist "%%~d" mkdir "%%~d" >nul 2>&1
exit /b 0
