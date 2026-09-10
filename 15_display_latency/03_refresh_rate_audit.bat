@echo off
call "%~dp0..\00_core\common.bat" >nul
powershell.exe -noprofile -command "get-ciminstance -namespace root\wmi -classname wmimonitorid -erroraction silentlycontinue | select instancename,userfriendlyname,serialnumberid | format-list; get-ciminstance win32_videocontroller | select name,currenthorizontalresolution,currentverticalresolution,currentrefreshrate | format-list"
