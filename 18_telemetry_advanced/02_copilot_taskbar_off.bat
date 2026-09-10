@echo off
call "%~dp0..\00_core\common.bat" >nul
powershell.exe -noprofile -command "get-itemproperty 'hkcu:\software\microsoft\windows\currentversion\explorer\advanced' -name showcopilotbutton -erroraction silentlycontinue | format-list"
echo estado atual somente leitura. nao aplicar politica de sistema sem confirmar versao do windows.
