@echo off
call "%~dp0..\00_core\common.bat" >nul
powershell.exe -noprofile -command "get-netipinterface -addressfamily ipv4 | where connectionstate -eq 'connected' | select interfacealias,nlmtu,connectionstate | format-table -autosize"
echo teste de mtu destrutivo nao e feito automaticamente.
