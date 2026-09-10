@echo off
setlocal EnableExtensions
call "%~dp0..\00_core\common.bat" >nul
echo Estado de VBS/HVCI:
msinfo32 /report "%nb_report%\msinfo_vbs_%random%.txt" >nul 2>&1
powershell.exe -NoProfile -Command "$d=Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction SilentlyContinue; if($d){$d | Select-Object VirtualizationBasedSecurityStatus,SecurityServicesRunning,SecurityServicesConfigured | Format-List}else{'Win32_DeviceGuard indisponivel'}"
echo Nao sera feita desativacao automatica: isso reduz protecoes do Windows e exige decisao consciente.
echo Se quiser testar impacto, crie ponto de restauracao, mude manualmente e faca benchmark com rollback documentado.
endlocal & exit /b 0