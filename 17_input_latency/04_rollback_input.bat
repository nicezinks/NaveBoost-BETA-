@echo off
call "%~dp0..\00_core\common.bat" >nul
echo restaure o plano de energia anterior pelo snapshot salvo antes da alteracao.
if exist "%nb_snapshot%\powercfg_before_input.txt" type "%nb_snapshot%\powercfg_before_input.txt"
