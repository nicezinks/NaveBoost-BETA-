@echo off
setlocal EnableExtensions
call "%~dp0..\00_core\common.bat" >nul
powershell.exe -NoProfile -Command "$d=Get-PhysicalDisk | Select-Object FriendlyName,MediaType,HealthStatus; $d | Format-Table -AutoSize; Get-Service SysMain -ErrorAction SilentlyContinue | Select-Object Name,Status,StartType | Format-List; Write-Host 'SysMain nao e desligado automaticamente: o beneficio depende do tipo de disco e do uso.'"
endlocal & exit /b 0