@echo off
call "%~dp0..\00_core\common.bat" >nul
call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5
set /p "drive=letra da unidade do jogo (ex c): "
set "drive=%drive::=%"
if not defined drive exit /b 2
powershell.exe -noprofile -command "$v=get-volume -driveletter $env:drive -erroraction stop; [pscustomobject]@{drive=$v.driveletter;label=$v.filesystemlabel;sizegb=[math]::round($v.size/1gb,1);freegb=[math]::round($v.sizeremaining/1gb,1)} | format-list; write-host 'indice por volume deve ser administrado pelo windows search; este modo so orienta.'"
