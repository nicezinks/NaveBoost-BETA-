@echo off
call "%~dp0..\00_core\common.bat" >nul
powershell.exe -noprofile -command "get-ciminstance win32_videocontroller | select-object name,driverversion,adapterram | format-table -autosize"
exit /b %errorlevel%
