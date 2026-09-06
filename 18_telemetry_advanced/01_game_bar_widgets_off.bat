@echo off
call "%~dp0..\00_core\common.bat" >nul
powershell.exe -noprofile -command "get-itemproperty 'hkcu:\software\microsoft\gamebar' -erroraction silentlycontinue | select autogamemodeenabled,showstartuppanel | format-list"
echo use o game bar/configuracoes do windows para escolher widgets; o script evita desligamento forcado.
