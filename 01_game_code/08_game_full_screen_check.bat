@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.5 adaptive
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

set /p "game=enter game exe path: "
powershell -noprofile -command "$p=get-item '%game%' -erroraction stop; $v=get-itemproperty 'hkcu:\software\microsoft\windows nt\currentversion\appcompatflags\layers' -erroraction silentlycontinue; if($v -and $v.psobject.properties.name -contains $p.fullname){$v.$($p.fullname)} else {'no per-app compatibility override recorded.'}"
endlocal
