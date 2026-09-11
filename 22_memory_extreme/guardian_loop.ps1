param(
    [string]$BaseDir,
    [ValidateRange(60,70)]
    [int]$MaxProcesses = 70,
    [ValidateRange(60,70)]
    [int]$TargetProcesses = 62,
    [double]$MaxUsedGB = 2.0,
    [switch]$Force
)

$stateDir = Join-Path $BaseDir "state"
if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }
$logPath   = Join-Path $stateDir "guardian_log.txt"
$stopFlag  = Join-Path $stateDir "guardian_stop.flag"
$purgePs1  = Join-Path $BaseDir "purge_standby.ps1"
$killerPs1 = Join-Path $BaseDir "kill_nonessential.ps1"

try { (Get-Process -Id $PID).PriorityClass = 'Idle' } catch {}
if ($TargetProcesses -gt $MaxProcesses) {
    throw "TargetProcesses não pode ser maior que MaxProcesses"
}

# Garante que versões antigas não fiquem concorrendo com esta instância.
$mutex = New-Object System.Threading.Mutex($false, 'NaveBoost_Inferno_Guardian')
$mutexOwned = $false
try { $mutexOwned = $mutex.WaitOne(0, $false) } catch {}
if (-not $mutexOwned) {
    Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - outra instancia ja esta ativa; esta encerrou sem alterar processos."
    exit 0
}

Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - guardian INFERNO iniciado (PID $PID). Acima de $MaxProcesses, reduz ate $TargetProcesses; memoria alvo $MaxUsedGB GB. Verificacao a cada 1s."

try {
$lastPurge = [datetime]::MinValue
while ($true) {
    if (Test-Path $stopFlag) {
        Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - stop flag encontrado, guardian encerrando."
        Remove-Item $stopFlag -Force -ErrorAction SilentlyContinue
        break
    }

    try {
        if (Test-Path $killerPs1) {
            & powershell -NoProfile -ExecutionPolicy Bypass -File $killerPs1 `
                -StateDir $stateDir -MinProcesses 60 -TargetProcesses $TargetProcesses `
                -MaxProcesses $MaxProcesses -MaxUsedGB $MaxUsedGB -Force | Out-Null
        }
        $procCount = @(Get-Process).Count
        try {
            $os = Get-CimInstance Win32_OperatingSystem
            $usedGB = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
        } catch { $usedGB = 0 }
        if ($usedGB -gt $MaxUsedGB -and (Get-Date) - $lastPurge -gt [timespan]::FromSeconds(5) -and (Test-Path $purgePs1)) {
            & powershell -NoProfile -ExecutionPolicy Bypass -File $purgePs1 | Out-Null
            $lastPurge = Get-Date
            Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - memoria acima de $MaxUsedGB GB; standby purgada."
        }
        Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - leitura: $procCount processos; cap $MaxProcesses; alvo $TargetProcesses; memoria $usedGB GB."
    } catch {
        Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - erro: $($_.Exception.Message)"
    }

    Start-Sleep -Seconds 1
}
} finally {
    if ($mutexOwned) {
        try { $mutex.ReleaseMutex() } catch {}
    }
    try { $mutex.Dispose() } catch {}
}