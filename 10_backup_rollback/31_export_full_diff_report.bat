@echo off
call "%~dp0..\00_core\common.bat" >nul
set "out=%nb_report%\full_diff_%random%.txt"
if not exist "%nb_snapshot%" mkdir "%nb_snapshot%" >nul 2>&1
(systeminfo & powercfg /getactivescheme & ipconfig /all & reg query "hklm\system\currentcontrolset\control\prioritycontrol" & reg query "hklm\software\microsoft\windows nt\currentversion\multimedia\systemprofile") > "%out%" 2>&1
echo relatorio: %out%
