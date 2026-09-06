@echo off
call "%~dp0..\00_core\common.bat" >nul
set "profile=%nb_data%\state\hardware_profile.json"
powershell.exe -noprofile -executionpolicy bypass -file "%~dp0\01_hardware_profile.ps1" > "%profile%"
if errorlevel 1 exit /b 2
type "%profile%"
