@echo off
call "%~dp0..\00_core\common.bat" >nul
if exist "%nb_snapshot%\network_registry_before.reg" reg import "%nb_snapshot%\network_registry_before.reg" else echo snapshot de rede nao encontrado.
