@echo off
call "%~dp0..\00_core\common.bat" >nul
call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5
powershell.exe -noprofile -command "$a=get-netipconfiguration | where-object {$_.netadapter.status -eq 'up' -and $_.ipv4defaultgateway}; $a | select interfacealias,interfaceindex,ipv4address | format-table -autosize; write-host 'nao aplicar nagle as cegas: use 19_backup e benchmark.'"
