@echo off
call "%~dp0..\00_core\common.bat" >nul
call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5
for /f "tokens=4" %%g in ('powercfg /getactivescheme') do set "scheme=%%g"
if not defined scheme exit /b 2
powercfg /setacvalueindex %scheme% sub_usb usbselective suspend 0 >nul 2>&1
powercfg /setactive %scheme% >nul 2>&1
echo suspensao seletiva usb desativada no ac se o plano expuser a opcao. benchmark recomendado.
