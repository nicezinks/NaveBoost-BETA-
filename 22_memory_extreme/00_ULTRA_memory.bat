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
echo  NaveBoost INFERNO 60-70 (v9.1)
echo  FAIXA PRATICA DE 60 A 70 PROCESSOS.
echo  Passou de 70: corta ate 62 para evitar oscilacao.
echo  Arvores de janelas visiveis e processos criticos ficam protegidos.
echo  O guardian antigo e encerrado antes da limpeza.
echo  Memoria: tenta manter abaixo de 2 GB sem tocar no jogo ou no desktop.
echo ==============================================
echo.
timeout /t 5

echo [0/7] Encerrando guardian antigo para evitar conflito...
call "%BASE%13_guardian_uninstall.bat" >nul 2>&1

powershell -NoProfile -ExecutionPolicy Bypass -File "%BASE%snapshot_before.ps1" -StateDir "%BASE%state"

powercfg /setacvalueindex SCHEME_MIN SUB_PROCESSOR PROCTHROTTLEMIN 100 >nul 2>&1
powercfg /setacvalueindex SCHEME_MIN SUB_PROCESSOR PROCTHROTTLEMAX 100 >nul 2>&1
powercfg /setdcvalueindex SCHEME_MIN SUB_PROCESSOR PROCTHROTTLEMIN 100 >nul 2>&1
powercfg /setdcvalueindex SCHEME_MIN SUB_PROCESSOR PROCTHROTTLEMAX 100 >nul 2>&1
powercfg /setactive SCHEME_MIN >nul 2>&1

echo [1/7] Mantendo o registro intacto para evitar conflito com outros otimizadores...

echo [2/7] Nao desabilitando servicos automaticamente: evita conflito com outros otimizadores...

echo [3/7] INFERNO PROCESS/MEMORY: cortando excesso acima de 70...
powershell -NoProfile -ExecutionPolicy Bypass -File "%BASE%kill_nonessential.ps1" -StateDir "%BASE%state" -MinProcesses 60 -TargetProcesses 62 -MaxProcesses 70 -MaxUsedGB 2.0 -Force

echo [4/7] Liberando working set de auxiliares em segundo plano...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$skip='Idle','System','Registry','smss','csrss','wininit','services','lsass','svchost','winlogon','fontdrvhost','dwm','explorer','sihost','audiodg','taskhostw','ctfmon','spoolsv','dllhost','WmiPrvSE','RuntimeBroker','SearchHost','StartMenuExperienceHost','ShellExperienceHost','TextInputHost','ApplicationFrameHost','SecurityHealthService','SecurityHealthSystray','MsMpEng','NisSrv','powershell','pwsh','conhost'; $visibleIds=New-Object System.Collections.Generic.HashSet[int]; Get-Process | Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -ne '' } | ForEach-Object { [void]$visibleIds.Add([int]$_.Id) }; Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class M { [DllImport(\"psapi.dll\")] public static extern bool EmptyWorkingSet(IntPtr h); }' -ErrorAction SilentlyContinue; Get-Process | Where-Object { $skip -notcontains $_.ProcessName -and -not $visibleIds.Contains([int]$_.Id) -and $_.MainWindowHandle -eq 0 -and $_.Id -ne $PID -and $_.WorkingSet64 -gt 20MB } | ForEach-Object { try { [M]::EmptyWorkingSet($_.Handle) | Out-Null } catch {} }; [GC]::Collect()"

echo [5/7] Mantendo o explorer.exe aberto para nao interromper o desktop...

echo [6/7] Purgando standby list (3x)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%BASE%purge_standby.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%BASE%purge_standby.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%BASE%purge_standby.ps1"

echo [7/7] INFERNO final: removendo processos acima de 70 que voltaram...
powershell -NoProfile -ExecutionPolicy Bypass -File "%BASE%kill_nonessential.ps1" -StateDir "%BASE%state" -MinProcesses 60 -TargetProcesses 62 -MaxProcesses 70 -MaxUsedGB 2.0 -Force

powershell -NoProfile -ExecutionPolicy Bypass -File "%BASE%report_run.ps1" -StateDir "%BASE%state"

echo.
echo NaveBoost INFERNO 60-70 aplicado.
echo Relatorio: %BASE%state\last_run_report.txt
echo Top 40 sobreviventes por RAM: %BASE%state\survivors_top40.txt
echo.
echo O relatorio process_cap.state mostra se o cap de 70 foi atingido.
echo.
echo Para restaurar servicos, energia e registro: 02_memory_restore.bat
endlocal