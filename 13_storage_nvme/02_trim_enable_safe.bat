@echo off
call "%~dp0..\00_core\common.bat" >nul
call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5
powershell.exe -noprofile -command "$d=get-physicaldisk; $d|select friendlyname,mediatype,healthstatus,operationalstatus | format-table -autosize; fsutil behavior set disabledeletenotify 0"
