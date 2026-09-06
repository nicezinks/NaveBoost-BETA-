@echo off
call "%~dp0..\00_core\common.bat" >nul
dxdiag /t "%nb_log%\dxdiag_display.txt" >nul 2>&1
wevtutil qe system /q:"*[system[(provider[@name='display'])]]" /c:30 /rd:true /f:text > "%nb_log%\display_events.txt" 2>nul
echo diagnostico salvo em %nb_log%.
