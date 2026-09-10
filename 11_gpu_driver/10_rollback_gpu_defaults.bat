@echo off
call "%~dp0..\00_core\common.bat" >nul
if not exist "%nb_snapshot%" (echo nenhum snapshot central encontrado.& exit /b 3)
echo para gpu/hags, restaure usando o snapshot .reg correspondente antes da alteracao.
explorer "%nb_snapshot%"
