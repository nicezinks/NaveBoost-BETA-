@echo off
setlocal EnableExtensions
call "%~dp0..\00_core\common.bat" >nul
echo Processos de overlay detectados:
powershell.exe -NoProfile -Command "Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match 'Discord|NVIDIA|Radeon|AMD|RTSS|Afterburner|GameBar|Xbox|Overwolf|Medal|OBS'} | Select-Object ProcessName,Id,CPU | Sort-Object ProcessName | Format-Table -AutoSize"
echo Este modulo somente audita. Desative overlays por jogo no aplicativo oficial.
endlocal & exit /b 0