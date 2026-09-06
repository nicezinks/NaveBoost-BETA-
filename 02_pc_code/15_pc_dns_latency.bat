@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

powershell -noprofile -command "1.1.1.1,8.8.8.8,9.9.9.9 | foreach-object { $t=measure-command { resolve-dnsname example.com -server $_ -erroraction silentlycontinue | out-null }; [pscustomobject]@{server=$_;ms=[math]::round($t.totalmilliseconds,1)} } | format-table -auto"
endlocal
