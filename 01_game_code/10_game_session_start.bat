@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

set /p "pn=game process name: "
set "start_ts=%date% %time%"
echo session started %start_ts% for %pn%>>%log%\game_sessions.log
powershell -noprofile -command "$p=get-process -name '%pn%' -erroraction silentlycontinue; if($p){$p | select name,id,cpu,ws,priorityclass | format-list}else{'process not found'}"
endlocal
