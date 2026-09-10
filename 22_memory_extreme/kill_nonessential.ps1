param(
    [string]$StateDir,
    [int]$MaxProcesses = 90
)

if (-not (Test-Path -LiteralPath $StateDir)) {
    New-Item -ItemType Directory -Path $StateDir -Force | Out-Null
}

$protectedNames = @(
    'Idle','System','Registry','smss','csrss','wininit','services','lsass','svchost',
    'winlogon','fontdrvhost','dwm','explorer','sihost','audiodg',
    'SecurityHealthService','MsMpEng','NisSrv','powershell','pwsh','conhost',
    'chrome','msedge','firefox','brave','opera','opera_gx'
)

$selfChainIds = New-Object System.Collections.Generic.HashSet[int]
try {
    $cur = Get-CimInstance Win32_Process -Filter "ProcessId=$PID"
    for ($i = 0; $i -lt 8 -and $cur; $i++) {
        [void]$selfChainIds.Add([int]$cur.ProcessId)
        $cur = Get-CimInstance Win32_Process -Filter "ProcessId=$($cur.ParentProcessId)" -ErrorAction SilentlyContinue
    }
} catch {}

$killedNames = New-Object System.Collections.Generic.List[string]
$before = @(Get-Process)
$countBefore = $before.Count

if ($countBefore -gt $MaxProcesses) {
    $excess = $countBefore - $MaxProcesses
    $visibleNames = @(
        $before | Where-Object {
            $_.MainWindowHandle -ne 0 -and -not [string]::IsNullOrWhiteSpace($_.MainWindowTitle)
        } | Select-Object -ExpandProperty ProcessName -Unique
    )

    $protected = @($protectedNames + $visibleNames)
    $victims = @(
        $before | Where-Object {
            $_.SessionId -ne 0 -and
            $protected -notcontains $_.ProcessName -and
            -not $selfChainIds.Contains([int]$_.Id) -and
            $_.MainWindowHandle -eq 0
        } | Sort-Object WorkingSet64 -Descending | Select-Object -First $excess
    )

    foreach ($v in $victims) {
        try {
            Stop-Process -Id $v.Id -Force -ErrorAction Stop
            $killedNames.Add($v.ProcessName)
        } catch {}
    }
}

$after = @(Get-Process)
$countAfter = $after.Count
$status = if ($countAfter -le $MaxProcesses) { 'OK' } else { 'LIMIT_REACHED' }

$after |
    Where-Object { $_.SessionId -ne 0 } |
    Sort-Object WorkingSet64 -Descending |
    Select-Object -First 40 ProcessName, Id, @{N='RAM_MB';E={[math]::Round($_.WorkingSet64/1MB,1)}} |
    Format-Table -AutoSize |
    Out-String -Width 200 |
    Set-Content -Encoding ASCII (Join-Path $StateDir "survivors_top40.txt")

$killedNames | Sort-Object -Unique | Set-Content -Encoding ASCII (Join-Path $StateDir "killed_processes.txt")
$killedNames.Count | Set-Content -Encoding ASCII (Join-Path $StateDir "killed_count.state")
@(
    "Status=$status"
    "MaxProcesses=$MaxProcesses"
    "Before=$countBefore"
    "After=$countAfter"
    "Killed=$($killedNames.Count)"
    "Note=Chrome, jogos, janelas visiveis e processos essenciais foram protegidos."
) | Set-Content -Encoding ASCII (Join-Path $StateDir "process_cap.state")

Write-Host "Teto de processos: $MaxProcesses | antes: $countBefore | depois: $countAfter | encerrados: $($killedNames.Count) | status: $status"