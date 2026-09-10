@echo off
call "%~dp0..\00_core\common.bat" >nul
powershell.exe -noprofile -command "get-ciminstance win32_processor | select name,numberofcores,numberoflogicalprocessors | format-list"
