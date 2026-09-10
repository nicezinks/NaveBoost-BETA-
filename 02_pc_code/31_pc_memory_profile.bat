@echo off
setlocal EnableExtensions
call "%~dp0..\00_core\common.bat" >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$m=@(Get-CimInstance Win32_PhysicalMemory | Select-Object BankLabel,DeviceLocator,Capacity,Speed,ConfiguredClockSpeed,PartNumber); $m | Format-Table -AutoSize; $slow=$m | Where-Object {$_.Speed -and $_.ConfiguredClockSpeed -and $_.ConfiguredClockSpeed -lt $_.Speed}; if($slow){Write-Host 'AVISO: clock configurado abaixo do nominal; confira XMP/DOCP/EXPO na BIOS.'} else {Write-Host 'A CIM nao confirma XMP/DOCP/EXPO; confira a BIOS manualmente.'}; Write-Host ('modulos=' + $m.Count)"
endlocal & exit /b %errorlevel%