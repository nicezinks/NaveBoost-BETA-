@echo off
call "%~dp0..\00_core\common.bat" >nul
powershell.exe -noprofile -command "get-physicaldisk | get-disk | select number,friendlyname,bustype,healthstatus | format-table -autosize"
