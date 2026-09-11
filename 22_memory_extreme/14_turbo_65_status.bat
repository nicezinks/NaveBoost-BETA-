@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -Command "$count=@(Get-Process).Count; $os=Get-CimInstance Win32_OperatingSystem; $used=[math]::Round(($os.TotalVisibleMemorySize-$os.FreePhysicalMemory)/1MB,2); $range=if($count -ge 60 -and $count -le 70){'OK - faixa 60-70'}elseif($count -gt 70){'ACIMA DO MAXIMO - INFERNO deve cortar ate 62'}else{'ABAIXO DA FAIXA - sem problema'}; Write-Host ('Processos: {0} | Memoria usada: {1} GB | {2}' -f $count,$used,$range)"
echo.
echo A faixa e 60-70; acima de 70 o INFERNO corta ate 62 e tenta liberar memoria.
echo Se estiver fora, rode 99_GOD_MODE_NOW.bat como administrador.
endlocal