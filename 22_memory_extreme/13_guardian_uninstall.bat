@echo off
setlocal EnableExtensions
net session >nul 2>&1
if not %errorlevel%==0 (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
set "BASE=%~dp0"
if not exist "%BASE%state" md "%BASE%state"

echo. > "%BASE%state\guardian_stop.flag"
echo Sinal de parada enviado. O guardian encerra em ate 1s sozinho.

timeout /t 2 >nul

schtasks /end /tn "NaveBoost_Guardian" >nul 2>&1
schtasks /delete /tn "NaveBoost_Guardian" /f >nul 2>&1

rem fallback: mata qualquer powershell orfao ainda rodando o guardian_loop.ps1
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_Process -Filter \"Name='powershell.exe'\" | Where-Object { $_.CommandLine -like '*guardian_loop.ps1*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"

echo Guardian removido (tarefa agendada + processo).
endlocal