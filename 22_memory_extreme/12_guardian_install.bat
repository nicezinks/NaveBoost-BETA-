@echo off
setlocal EnableExtensions
net session >nul 2>&1
if not %errorlevel%==0 (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
set "BASE=%~dp0"
if not exist "%BASE%state" md "%BASE%state"

echo ==============================================
echo  NaveBoost Guardian - instalando vigia de fundo
echo  Meta: maximo 90 processos / max 2GB usados.
echo  Roda escondido a cada ~45s, PRA SEMPRE (ate voce
echo  desinstalar). So encerra o excedente sem janela visivel.
echo  Chrome, jogos e janelas visiveis NUNCA sao fechados.
echo  O teto pode ficar acima de 90 se o Windows proteger tudo.
echo ==============================================

schtasks /create /tn "NaveBoost_Guardian" /tr "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%BASE%guardian_loop.ps1\" -BaseDir \"%BASE%\" -MaxProcesses 90 -MaxUsedGB 2.0" /sc onlogon /rl highest /f >nul 2>&1

if exist "%BASE%state\guardian_stop.flag" del /f /q "%BASE%state\guardian_stop.flag" >nul 2>&1

schtasks /run /tn "NaveBoost_Guardian" >nul 2>&1

echo Guardian instalado e rodando.
echo Log ao vivo em: %BASE%state\guardian_log.txt
echo Pra parar: 13_guardian_uninstall.bat
endlocal