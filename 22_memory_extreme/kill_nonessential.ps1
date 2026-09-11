param(
    [string]$StateDir,
    [ValidateRange(60,70)]
    [int]$MinProcesses = 60,
    [ValidateRange(60,70)]
    [int]$MaxProcesses = 70,
    [ValidateRange(60,70)]
    [int]$TargetProcesses = 62,
    [ValidateRange(1,8)]
    [double]$MaxUsedGB = 2.0,
    [switch]$Force,
    [switch]$ProcessOnly
)

$ErrorActionPreference = 'SilentlyContinue'
if (-not (Test-Path -LiteralPath $StateDir)) {
    New-Item -ItemType Directory -Path $StateDir -Force | Out-Null
}
if ($MinProcesses -gt $TargetProcesses -or $TargetProcesses -gt $MaxProcesses) {
    throw "A ordem precisa ser MinProcesses <= TargetProcesses <= MaxProcesses"
}

# Esta lista é deliberadamente conservadora. Um cap de processos não vale um
# desktop quebrado: processos da sessão 0, drivers, shell e segurança ficam fora.
$protectedNames = @(
    'Idle','System','Registry','smss','csrss','wininit','services','lsass','svchost',
    'winlogon','fontdrvhost','dwm','explorer','sihost','audiodg','taskhostw',
    'ctfmon','spoolsv','dllhost','WmiPrvSE','RuntimeBroker','SearchHost',
    'StartMenuExperienceHost','ShellExperienceHost','TextInputHost','ApplicationFrameHost',
    'SecurityHealthService','SecurityHealthSystray','MsMpEng','NisSrv',
    'powershell','pwsh','conhost','cmd','WindowsTerminal'
)
$optionalNames = @(
    'OneDrive','Teams','ms-teams','Widgets','WidgetService','YourPhone',
    'PhoneExperienceHost','GameBar','GameBarFTServer','XboxAppServices',
    'SearchIndexer','SearchProtocolHost','SearchFilterHost','Microsoft.SharePoint',
    'AdobeCollabSync','CCXProcess','GoogleCrashHandler','GoogleCrashHandler64',
    'crashpad_handler','updater','Update','opera_crashreporter'
)
$browserNames = @('chrome','msedge','firefox','brave','opera','opera_gx')
$configuredProtectedNames = @()
$protectedFile = Join-Path $StateDir 'protected_processes.txt'
if (Test-Path -LiteralPath $protectedFile) {
    $configuredProtectedNames = @(Get-Content -LiteralPath $protectedFile |
        Where-Object { $_ -and -not $_.Trim().StartsWith('#') } |
        ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_.Trim()) })
}
$protectedNames = @($protectedNames + $configuredProtectedNames)

function Get-UsedMemoryGB {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        return [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
    } catch { return 0 }
}

function Get-ProcessSnapshot {
    $items = @()
    $cim = @{}
    try {
        foreach ($row in @(Get-CimInstance Win32_Process)) {
            $cim[[int]$row.ProcessId] = $row
        }
    } catch {}
    foreach ($p in @(Get-Process)) {
        $parent = 0
        if ($cim.ContainsKey([int]$p.Id)) { $parent = [int]$cim[[int]$p.Id].ParentProcessId }
        $items += [pscustomobject]@{
            Id = [int]$p.Id
            Name = [string]$p.ProcessName
            ParentId = $parent
            SessionId = [int]$p.SessionId
            Window = ($p.MainWindowHandle -ne 0 -and -not [string]::IsNullOrWhiteSpace($p.MainWindowTitle))
            WorkingSet = [int64]$p.WorkingSet64
        }
    }
    return @($items)
}

$selfChainIds = New-Object System.Collections.Generic.HashSet[int]
try {
    $cur = Get-CimInstance Win32_Process -Filter "ProcessId=$PID"
    for ($i = 0; $i -lt 12 -and $cur; $i++) {
        [void]$selfChainIds.Add([int]$cur.ProcessId)
        $cur = Get-CimInstance Win32_Process -Filter "ProcessId=$($cur.ParentProcessId)" -ErrorAction SilentlyContinue
    }
} catch {}

$before = @(Get-ProcessSnapshot)
$countBefore = $before.Count
$visibleIds = New-Object System.Collections.Generic.HashSet[int]
foreach ($p in $before) {
    if ($p.Window) { [void]$visibleIds.Add($p.Id) }
}

# Protege a árvore de janelas visíveis (inclusive filhos do jogo) e a cadeia do guardian.
$byParent = @{}
foreach ($p in $before) {
    if (-not $byParent.ContainsKey($p.ParentId)) { $byParent[$p.ParentId] = @() }
    $byParent[$p.ParentId] += $p.Id
}
$treeProtected = New-Object System.Collections.Generic.HashSet[int]
function Add-Descendants([int]$id) {
    if (-not $treeProtected.Add($id)) { return }
    if ($byParent.ContainsKey($id)) {
        foreach ($child in @($byParent[$id])) { Add-Descendants $child }
    }
}
foreach ($id in $visibleIds) { Add-Descendants $id }
foreach ($id in $selfChainIds) { [void]$treeProtected.Add($id) }

$killedNames = New-Object System.Collections.Generic.List[string]
$trimmedCount = 0
if (-not ('NaveBoost.MemoryNative' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class MemoryNative {
    [DllImport("psapi.dll")]
    public static extern bool EmptyWorkingSet(IntPtr h);
}
'@ -Namespace NaveBoost -Name MemoryNative -ErrorAction SilentlyContinue
}
$attempts = 0
while ($attempts -lt 200) {
    $current = @(Get-ProcessSnapshot)
    $currentCount = $current.Count
    $currentUsedGB = Get-UsedMemoryGB
    $needsCount = $currentCount -gt $MaxProcesses
    $needsMemory = $Force -and -not $ProcessOnly -and
                   $currentUsedGB -gt $MaxUsedGB -and $currentCount -gt $MinProcesses
    if (-not ($needsCount -or $needsMemory)) { break }

    $candidates = @(
        $current | Where-Object {
            $_.SessionId -ne 0 -and
            $protectedNames -notcontains $_.Name -and
            -not $treeProtected.Contains($_.Id) -and
            $_.Id -ne $PID -and
            -not $_.Window
        } | ForEach-Object {
            $priority = if ($optionalNames -contains $_.Name) { 0 } elseif ($browserNames -contains $_.Name) { 30 } else { 10 }
            [pscustomobject]@{ Process = $_; Priority = $priority }
        } | Sort-Object Priority, @{Expression={$_.Process.WorkingSet}; Descending=$true}
    )
    if (-not $candidates) { break }

    $victim = $candidates[0].Process
    try {
        Stop-Process -Id $victim.Id -Force -ErrorAction Stop
        $killedNames.Add($victim.Name)
    } catch {}
    $attempts++
}

$after = @(Get-ProcessSnapshot)
$countAfter = $after.Count
$usedAfterGB = Get-UsedMemoryGB

if ($Force -and -not $ProcessOnly -and $usedAfterGB -gt $MaxUsedGB) {
    foreach ($p in $after) {
        if ($p.SessionId -eq 0 -or $protectedNames -contains $p.Name -or
            $treeProtected.Contains($p.Id) -or $p.Window -or $p.WorkingSet -lt 20MB) {
            continue
        }
        try {
            $proc = Get-Process -Id $p.Id -ErrorAction Stop
            [NaveBoost.MemoryNative]::EmptyWorkingSet($proc.Handle) | Out-Null
            $trimmedCount++
        } catch {}
    }
    [GC]::Collect()
    $usedAfterGB = Get-UsedMemoryGB
}
$status = if ($countAfter -gt $MaxProcesses) { 'LIMIT_REACHED_PROTECTED' }
          elseif ($Force -and -not $ProcessOnly -and $usedAfterGB -gt $MaxUsedGB) { 'MEMORY_LIMIT_REACHED_PROTECTED' }
          elseif ($countAfter -lt $MinProcesses) { 'BELOW_RANGE' }
          else { 'IN_RANGE' }

$after | Where-Object { $_.SessionId -ne 0 } |
    Sort-Object WorkingSet -Descending |
    Select-Object -First 40 Name, Id, @{N='RAM_MB';E={[math]::Round($_.WorkingSet/1MB,1)}} |
    Format-Table -AutoSize | Out-String -Width 200 |
    Set-Content -Encoding ASCII (Join-Path $StateDir "survivors_top40.txt")

$killedNames | Sort-Object -Unique | Set-Content -Encoding ASCII (Join-Path $StateDir "killed_processes.txt")
$killedNames.Count | Set-Content -Encoding ASCII (Join-Path $StateDir "killed_count.state")
@(
    "Status=$status"
    "MinProcesses=$MinProcesses"
    "TargetProcesses=$TargetProcesses"
    "MaxProcesses=$MaxProcesses"
    "Before=$countBefore"
    "After=$countAfter"
    "UsedGB=$usedAfterGB"
    "Killed=$($killedNames.Count)"
    "Trimmed=$trimmedCount"
    "Mode=$(if ($Force) { 'FORCE' } else { 'SAFE' })"
    "ProcessMode=$(if ($ProcessOnly) { 'PROCESS_ONLY' } else { 'PROCESS_AND_MEMORY' })"
    "Note=Faixa pratica 60-70; ao passar de 70 reduz ate 62. Memoria tenta ficar abaixo de 2 GB sem tocar em janelas visiveis, arvores do jogo ou processos criticos."
) | Set-Content -Encoding ASCII (Join-Path $StateDir "process_cap.state")

Write-Host "Alvo apos excesso: $TargetProcesses | faixa: $MinProcesses-$MaxProcesses | antes: $countBefore | depois: $countAfter | memoria: $usedAfterGB GB | encerrados: $($killedNames.Count) | status: $status"