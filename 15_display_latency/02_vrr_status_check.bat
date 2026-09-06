@echo off
call "%~dp0..\00_core\common.bat" >nul
powershell.exe -noprofile -command "get-ciminstance -namespace root\wmi -classname wmimonitorbasicdisplayparams -erroraction silentlycontinue | select instancename,active | format-table -autosize"
echo g-sync/freesync precisa ser confirmado no driver; apis genericas do windows nao expoem todo o estado.
