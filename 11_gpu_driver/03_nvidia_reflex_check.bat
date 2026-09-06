@echo off
call "%~dp0..\00_core\common.bat" >nul
set /p "game=nome do executavel do jogo (sem .exe): "
if not defined game exit /b 2
powershell.exe -noprofile -command "$p=get-process -name $env:game -erroraction silentlycontinue; if($p){$p|select name,id,mainwindowtitle}else{'processo nao encontrado; reflex deve ser configurado dentro do jogo quando suportado.'}"
