@echo off
setlocal EnableExtensions
call "%~dp0..\00_core\common.bat" >nul
echo Verificando informacoes disponiveis da GPU:
powershell.exe -NoProfile -Command "Get-CimInstance Win32_VideoController | Select-Object Name,VideoModeDescription,DriverVersion,AdapterRAM | Format-List"
echo ReBAR e Above 4G dependem de BIOS, placa-mae, GPU e driver.
echo Este modulo nao altera BIOS e nao presume que a ausencia de um campo signifique desativado.
endlocal & exit /b 0