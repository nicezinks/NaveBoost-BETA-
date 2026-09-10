@echo off
call "%~dp0..\00_core\common.bat" >nul
set /p "pn=[PROCESSO/APLICACAO] nome com ou sem .exe: "
if not defined pn exit /b 2
powershell.exe -noprofile -command "$p=get-process -name $env:pn -erroraction silentlycontinue; if(-not $p){throw 'processo nao encontrado.'}; $c=(get-ciminstance win32_processor | measure-object numberofcores -sum).sum; [pscustomobject]@{process=$p.name;pid=$p.id;physicalcores=$c;suggested='audit only: nao aplicar afinidade automaticamente'} | format-list"
