@echo off
call "%~dp0..\00_core\common.bat" >nul
powershell.exe -noprofile -command "get-ciminstance win32_perfformatteddata_perfos_system | select-object timestamp_object,processes,contextswitchespersec | format-list"
echo timer resolution real-time depende do aplicativo/tool de medicao; este modulo nao forca timer.
