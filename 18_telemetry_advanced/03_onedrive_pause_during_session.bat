@echo off
call "%~dp0..\00_core\common.bat" >nul
where onedrive.exe >nul 2>&1 && echo onedrive localizado no path || echo onedrive fora do path; use o cliente para pausar sincronizacao manualmente.
echo o naveboost nao encerra a sincronizacao automaticamente para evitar perda de estado.
