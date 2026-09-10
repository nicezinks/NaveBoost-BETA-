@echo off
setlocal EnableExtensions EnableDelayedExpansion
call "%~dp0..\00_core\common.bat" >nul
set "out=%nb_report%\network_jitter_%random%.txt"
echo NaveBoost - teste de Wi-Fi/cabo > "%out%"
echo Adaptadores ativos:>>"%out%"
powershell.exe -NoProfile -Command "Get-NetAdapter -Physical | Where-Object Status -eq 'Up' | Select-Object Name,InterfaceDescription,LinkSpeed,MediaType | Format-Table -AutoSize" >> "%out%" 2>&1
for /f "tokens=3" %%g in ('ipconfig ^| findstr /i "Default Gateway"') do (
  echo Gateway %%g>>"%out%"
  powershell.exe -NoProfile -Command "$r=Test-Connection -ComputerName '%%g' -Count 20 -ErrorAction SilentlyContinue; if($r){$r | Measure-Object ResponseTime -Average -Maximum -Minimum | Format-List}else{'sem resposta'}" >> "%out%" 2>&1
)
echo Teste externo 1.1.1.1>>"%out%"
powershell.exe -NoProfile -Command "$r=Test-Connection -ComputerName '1.1.1.1' -Count 20 -ErrorAction SilentlyContinue; if($r){$r | Measure-Object ResponseTime -Average -Maximum -Minimum | Format-List}else{'sem resposta'}" >> "%out%" 2>&1
type "%out%"
echo Relatorio: %out%
endlocal & exit /b 0