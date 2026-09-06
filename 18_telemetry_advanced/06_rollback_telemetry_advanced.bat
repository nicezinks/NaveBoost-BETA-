@echo off
call "%~dp0..\00_core\common.bat" >nul
net start wsearch >nul 2>&1
echo windows search solicitado para iniciar; onedrive deve ser retomado pelo proprio cliente.
