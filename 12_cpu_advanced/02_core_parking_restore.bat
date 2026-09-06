@echo off
call "%~dp0..\00_core\common.bat" >nul
call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5
echo windows deve manter o valor anterior apenas se voce o salvou. reaplicar valores genericos pode sobrescrever tuning oem.
echo use powercfg /query e seu backup para restauracao exata.
powercfg /query > "%nb_snapshot%\powercfg_current.txt"
