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
set "nb_backup=%nb_data%\backups"
set "nb_export=%nb_data%\exports"
set "nb_cache=%nb_data%\cache"
set "nb_diagnostic=%nb_data%\diagnostics"
set "nb_version=unknown"
for /f "usebackq delims=" %%v in (`powershell.exe -NoProfile -Command "$v=Get-Content -Raw -LiteralPath '%nb_root%\00_core\version.json' ^| ConvertFrom-Json; $v.version"`) do set "nb_version=%%v"
for %%d in ("%nb_log%" "%nb_snapshot%" "%nb_bench%" "%nb_report%" "%nb_profile%" "%nb_state%" "%nb_backup%" "%nb_export%" "%nb_cache%" "%nb_diagnostic%") do if not exist "%%~d" mkdir "%%~d" >nul 2>&1
exit /b 0
