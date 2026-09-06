@echo off
call "%~dp0..\00_core\common.bat" >nul
echo a taxa de polling e definida pelo firmware/software do fabricante.
powershell.exe -noprofile -command "get-pnpdevice -class mouse -status ok | select friendlyname,instanceid | format-table -autosize"
