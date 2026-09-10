param(
    [string]$BaseDir,
    [int]$MaxProcesses = 90,
    [double]$MaxUsedGB = 2.0
)

$stateDir = Join-Path $BaseDir "state"
if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }
$logPath   = Join-Path $stateDir "guardian_log.txt"
$stopFlag  = Join-Path $stateDir "guardian_stop.flag"
$purgePs1  = Join-Path $BaseDir "purge_standby.ps1"

try { (Get-Process -Id $PID).PriorityClass = 'Idle' } catch {}

$keepNames = @(
    'Idle','System','Registry','smss','csrss','wininit','services','lsass','svchost',
    'winlogon','fontdrvhost','dwm','explorer','sihost','audiodg',
    'SecurityHealthService','MsMpEng','NisSrv','powershell','pwsh','conhost',
    'chrome','msedge','firefox','brave','opera','opera_gx'
)

Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NB_W { [DllImport("psapi.dll")] public static extern bool EmptyWorkingSet(IntPtr h); }' -ErrorAction SilentlyContinue

Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - guardian iniciado (PID $PID). Meta: <= $MaxProcesses processos, <= $MaxUsedGB GB usados."

$loopCount = 0
$totalMB = (Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize / 1024

while ($true) {
    if (Test-Path $stopFlag) {
        Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - stop flag encontrado, guardian encerrando."
        Remove-Item $stopFlag -Force -ErrorAction SilentlyContinue
        break
    }

    try {
        $allProcesses = @(Get-Process)
        $procCount = $allProcesses.Count
        $visible = $allProcesses | Where-Object {
            $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -ne ''
        }
        $visibleProcs = $visible | Select-Object -ExpandProperty ProcessName -Unique

        $protect = $keepNames + $visibleProcs

        $killed = New-Object System.Collections.Generic.List[string]
        if ($procCount -gt $MaxProcesses) {
            $excess = $procCount - $MaxProcesses
            $candidates = @(
                $allProcesses | Where-Object {
                    $_.SessionId -ne 0 -and
                    $protect -notcontains $_.ProcessName -and
                    $_.Id -ne $PID -and
                    $_.MainWindowHandle -eq 0
                } | Sort-Object WorkingSet64 -Descending | Select-Object -First $excess
            )
            $candidates | ForEach-Object {
                try {
                    Stop-Process -Id $_.Id -Force -ErrorAction Stop
                    $killed.Add($_.ProcessName)
                } catch {}
            }
        }

        Get-Process | Where-Object {
            $protect -notcontains $_.ProcessName -and
            $_.MainWindowHandle -eq 0 -and
            $_.WorkingSet64 -gt 20MB -and
            $_.Id -ne $PID
        } | ForEach-Object {
            try { [NB_W]::EmptyWorkingSet($_.Handle) | Out-Null } catch {}
        }
        [GC]::Collect()

        if ($killed.Count -gt 0) {
            Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - fundo: matou $($killed.Count) -> $($killed -join ', ')"
        }

        $procCount = (Get-Process).Count
        try {
            $availMB = (Get-Counter '\Memory\Available MBytes').CounterSamples[0].CookedValue
        } catch {
            $availMB = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1024
        }
        $usedGB = [math]::Round(($totalMB - $availMB) / 1024, 2)

        $overCap = ($procCount -gt $MaxProcesses) -or ($usedGB -gt $MaxUsedGB)

        if ($overCap -and (Test-Path $purgePs1)) {
            & powershell -NoProfile -ExecutionPolicy Bypass -File $purgePs1 | Out-Null
            [GC]::Collect(); [GC]::WaitForPendingFinalizers(); [GC]::Collect()

            $procCount2 = (Get-Process).Count
            try { $availMB2 = (Get-Counter '\Memory\Available MBytes').CounterSamples[0].CookedValue } catch { $availMB2 = $availMB }
            $usedGB2 = [math]::Round(($totalMB - $availMB2) / 1024, 2)

            if (($procCount2 -gt $MaxProcesses) -or ($usedGB2 -gt $MaxUsedGB)) {
                $visRAMmb = [math]::Round((($visible | Measure-Object WorkingSet64 -Sum).Sum) / 1MB, 0)
                Add-Content -Path $logPath -Value ("$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - META ESTOURADA apos purga: " +
                    "$procCount2 processos (meta $MaxProcesses) / $usedGB2 GB usados (meta $MaxUsedGB). " +
                    "Janelas visiveis protegidas: $($visibleProcs.Count) apps, $($visible.Count) processos, ~$visRAMmb MB. " +
                    "Isso e o custo do que esta aberto na tela - nao fechado por regra.")
            } else {
                Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - meta recuperada apos purga: $procCount2 processos / $usedGB2 GB."
            }
        }

        if ($procCount -gt $MaxProcesses -and $killed.Count -eq 0) {
            Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - teto nao atingido: todos os candidatos estao protegidos, visiveis ou indisponiveis."
        }

        $loopCount++
    } catch {
        Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - erro: $($_.Exception.Message)"
    }

    Start-Sleep -Seconds 45
}