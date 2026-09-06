@echo off
call "%~dp0..\00_core\common.bat" >nul
set "out=%nb_report%\session_%random%.txt"
(systeminfo & powercfg /getactivescheme & ipconfig /all) > "%out%"
echo hardware + energia + rede exportados para %out%
