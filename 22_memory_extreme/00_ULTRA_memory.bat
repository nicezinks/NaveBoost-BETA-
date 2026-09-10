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
echo  NaveBoost ULTRA DEMONIACO memory mode (v5 - GOD)
echo  TETO DE 90 PROCESSOS - modo agressivo controlado.
echo  O excedente sem janela visivel pode ser encerrado.
echo  Chrome, jogos, janelas visiveis e antivirus ficam protegidos.
echo  O Windows pode manter mais de 90 se nao houver candidato seguro.
echo ==============================================
echo.
timeout /t 5

powershell -NoProfile -ExecutionPolicy Bypass -File "%BASE%snapshot_before.ps1" -StateDir "%BASE%state"

powercfg /setactive SCHEME_MIN >nul 2>&1

echo [1/6] Aplicando ajuste de registro pra agrupar svchost (so vale apos reboot)...
reg import "%BASE%04_svchost_consolidate.reg" >nul 2>&1

echo [2/6] Servicos do Windows preservados; sem desabilitacao automatica...

echo [3/6] Cortando somente o excedente ate 90 processos...
powershell -NoProfile -ExecutionPolicy Bypass -File "%BASE%kill_nonessential.ps1" -StateDir "%BASE%state" -MaxProcesses 90

echo [4/6] Liberando working set apenas de auxiliares em segundo plano...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$skip='Idle','System','Registry','smss','csrss','wininit','services','lsass','svchost','winlogon','fontdrvhost','dwm','explorer','sihost','audiodg','SecurityHealthService','MsMpEng','NisSrv','chrome','msedge','firefox','brave','opera','opera_gx','powershell','pwsh','conhost'; $visible=@(Get-Process | Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -ne '' } | Select-Object -ExpandProperty ProcessName -Unique); Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class M { [DllImport(\"psapi.dll\")] public static extern bool EmptyWorkingSet(IntPtr h); }' -ErrorAction SilentlyContinue; Get-Process | Where-Object { $skip -notcontains $_.ProcessName -and $visible -notcontains $_.ProcessName -and $_.MainWindowHandle -eq 0 -and $_.Id -ne $PID -and $_.WorkingSet64 -gt 20MB } | ForEach-Object { try { [M]::EmptyWorkingSet($_.Handle) | Out-Null } catch {} }; [GC]::Collect()"

echo [5/6] Mantendo o explorer.exe aberto para nao interromper o desktop...

echo [6/6] Purgando standby list (3x)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%BASE%purge_standby.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%BASE%purge_standby.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%BASE%purge_standby.ps1"

powershell -NoProfile -ExecutionPolicy Bypass -File "%BASE%report_run.ps1" -StateDir "%BASE%state"

echo.
echo NaveBoost ULTRA DEMONIACO (v5) aplicado.
echo Relatorio: %BASE%state\last_run_report.txt
echo Top 40 sobreviventes por RAM: %BASE%state\survivors_top40.txt
echo.
echo O relatorio process_cap.state mostra se o teto foi atingido.
echo.
echo Para reverter o agrupamento de svchost: 02_memory_restore.bat e 05_svchost_restore.reg
endlocal