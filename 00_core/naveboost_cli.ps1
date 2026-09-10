[CmdletBinding()]
param(
    [ValidateSet('start','stop','diagnostic','snapshot','rollback','discover','telemetry','bottleneck','adaptive-scan','health','benchmark','report','verify','turbo','help')]
    [string]$Action = 'diagnostic',
    [ValidateSet('safe','competitive','low-latency','quality','low-end','custom')]
    [string]$Profile = 'safe',
    [Alias('ProcessName','Application')]
    [string]$GameExe,
    [string]$LogPath,
    [ValidateSet('normal','abovenormal','high')]
    [string]$Priority = 'abovenormal',
    [int]$TelemetrySeconds = 30,
    [string]$BaselineCsv,
    [string]$PostCsv,
    [ValidateRange(0,100)]
    [double]$BenchmarkMargin = 1.0,
    [ValidateRange(20,1000000)]
    [int]$MinBenchmarkFrames = 100,
    [switch]$Silent,
    [switch]$DryRun,
    [switch]$CloseBackground,
    [switch]$Experimental,
    [ValidateSet(0,1,2)]
    [int]$HagsMode = 0,
    [switch]$JsonOutput,
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$VersionPath = Join-Path $PSScriptRoot 'version.json'
$VersionInfo = Get-Content -Raw -LiteralPath $VersionPath | ConvertFrom-Json
$NaveBoostVersion = [string]$VersionInfo.version
if ([string]::IsNullOrWhiteSpace($NaveBoostVersion)) { throw 'versão central ausente em 00_core/version.json' }
$Data = Join-Path $Root 'data'
$Dirs = @('logs','snapshots','benchmarks','reports','profiles','state','backups','exports','cache','diagnostics') | ForEach-Object { Join-Path $Data $_ }
$Dirs | ForEach-Object { New-Item -ItemType Directory -Force -Path $_ | Out-Null }
$Log = if ($LogPath) { [Environment]::ExpandEnvironmentVariables($LogPath) } else { Join-Path $Data 'logs\naveboost.log' }
$logParent = Split-Path -Parent $Log
if ($logParent) { New-Item -ItemType Directory -Force -Path $logParent | Out-Null }
$SessionFile = Join-Path $Data 'state\active_session.json'
$LastSession = Join-Path $Data 'state\last_session.json'
$SessionLock = Join-Path $Data 'state\session.lock.json'
$SessionId = [guid]::NewGuid().ToString()
$script:GameResolvedPath = $null

function Write-Log([string]$Message, [string]$Level = 'INFO') {
    $line = '{0} [{1}] {2}' -f (Get-Date).ToString('o'), $Level, $Message
    Add-Content -LiteralPath $Log -Value $line -Encoding UTF8
    if (-not $Silent) { Write-Host $line }
}

function Acquire-SessionLock {
    if (Test-Path -LiteralPath $SessionLock) {
        try {
            $existing = Get-Content -Raw -LiteralPath $SessionLock | ConvertFrom-Json
            $ownerPid = [int]$existing.OwnerPid
            $owner = Get-Process -Id $ownerPid -ErrorAction SilentlyContinue
            if ($owner -and $ownerPid -ne $PID) {
                throw "já existe uma sessão ativa (PID $ownerPid, sessão $($existing.SessionId)); use --rollback após verificar o estado"
            }
            Remove-Item -LiteralPath $SessionLock -Force -ErrorAction SilentlyContinue
            Write-Log 'lock abandonado removido após validação do processo proprietário' 'WARN'
        } catch {
            if ($_.Exception.Message -match 'já existe uma sessão ativa') { throw }
            Remove-Item -LiteralPath $SessionLock -Force -ErrorAction SilentlyContinue
            Write-Log 'lock inválido removido; uma nova sessão será criada' 'WARN'
        }
    }
    $payload = [pscustomobject]@{
        SessionId = $SessionId
        OwnerPid = $PID
        Created = (Get-Date).ToString('o')
        Computer = $env:COMPUTERNAME
    } | ConvertTo-Json -Depth 4
    $stream = $null
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
        $stream = [IO.File]::Open($SessionLock, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $stream.Write($bytes, 0, $bytes.Length)
    } catch {
        throw "não foi possível adquirir o lock da sessão: $($_.Exception.Message)"
    } finally {
        if ($stream) { $stream.Dispose() }
    }
}

function Release-SessionLock {
    if (-not (Test-Path -LiteralPath $SessionLock)) { return }
    try {
        $lock = Get-Content -Raw -LiteralPath $SessionLock | ConvertFrom-Json
        if ([int]$lock.OwnerPid -eq $PID) {
            Remove-Item -LiteralPath $SessionLock -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Log "não foi possível liberar o lock: $($_.Exception.Message)" 'WARN'
    }
}

function Write-JsonReport([string]$Path, [object]$Value) {
    $parent = Split-Path -Parent $Path
    if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    $Value | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Invoke-Logged([string]$File, [string[]]$Arguments) {
    Write-Log ("executando: {0} {1}" -f $File, ($Arguments -join ' '))
    if ($DryRun) { Write-Log 'dry-run: comando nao executado'; return 0 }
    & $File @Arguments 2>&1 | ForEach-Object { Write-Log ([string]$_) }
    return $LASTEXITCODE
}

function Invoke-AdaptiveSessionActions([ValidateSet('apply','restore')][string]$Mode, [string]$Bottleneck) {
    $module = Join-Path $Root '21_adaptive_engine\adaptive_session.ps1'
    if ($Mode -eq 'apply' -and -not $Experimental) { return }
    if ($Mode -eq 'restore' -and -not (Test-Path -LiteralPath (Join-Path $Data 'state\adaptive_session_actions.json'))) { return }
    $arguments = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$module,'-Action',$Mode,'-Bottleneck',$Bottleneck,'-HagsMode',$HagsMode)
    if ($Mode -eq 'apply' -and $Experimental) { $arguments += '-Experimental' }
    if ($GameExe) { $arguments += @('-GamePath',$GameExe) }
    Write-Log "adaptive_session $Mode bottleneck=$Bottleneck"
    if ($DryRun) { Write-Log 'dry-run: ações adaptativas não executadas'; return }
    & powershell.exe @arguments 2>&1 | ForEach-Object { Write-Log ([string]$_) }
    if ($LASTEXITCODE -ne 0) { throw "adaptive_session retornou codigo $LASTEXITCODE" }
}

function Get-ActiveScheme {
    $line = & powercfg.exe /getactivescheme 2>$null | Out-String
    $m = [regex]::Match($line, '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}')
    if ($m.Success) { return $m.Value }
    return $null
}

function Test-Administrator {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Confirm-Action([string]$Text) {
    if ($Silent) { return $true }
    if ($DryRun) { return $true }
    $answer = Read-Host "$Text [s/N]"
    return $answer -match '^(s|sim|y|yes)$'
}

function Get-ProcessSnapshot([string]$Name) {
    @(Get-Process -Name $Name -ErrorAction SilentlyContinue | ForEach-Object {
        $path = $null
        try { $path = $_.Path } catch {}
        $affinity = $null
        try { $affinity = $_.ProcessorAffinity.ToInt64() } catch {}
        [pscustomobject]@{
            Id = $_.Id
            Name = $_.ProcessName
            Path = $path
            Priority = [string]$_.PriorityClass
            Affinity = $affinity
        }
    })
}

function Resolve-GameName {
    if (-not $GameExe) {
        if ($Silent) { return $null }
        $script:GameExe = Read-Host '[PROCESSO/APLICACAO] nome com ou sem .exe; caminho completo com .exe'
    }
    if (-not $GameExe) { return $null }
    $raw = $GameExe.Trim().Trim('"')
    $looksLikePath = $raw -match '[\\/:]'
    if (Test-Path -LiteralPath $raw -PathType Leaf) {
        $resolved = (Resolve-Path -LiteralPath $raw).Path
        if ([IO.Path]::GetExtension($resolved) -ine '.exe') {
            throw '[PROCESSO/APLICACAO] um caminho de arquivo precisa apontar para um .exe'
        }
        $script:GameResolvedPath = $resolved
    } elseif ($looksLikePath) {
        throw "[PROCESSO/APLICACAO] caminho não encontrado: $raw"
    }
    $script:GameExe = $raw
    return [IO.Path]::GetFileNameWithoutExtension($raw)
}

function Get-GameProcesses([string]$Name) {
    if (-not $Name) { return @() }
    $items = @(Get-Process -Name $Name -ErrorAction SilentlyContinue)
    if (-not $script:GameResolvedPath) { return $items }
    @($items | Where-Object {
        $path = $null
        try { $path = $_.Path } catch { try { $path = $_.MainModule.FileName } catch {} }
        $path -and ([IO.Path]::GetFullPath($path) -ieq [IO.Path]::GetFullPath($script:GameResolvedPath))
    })
}

function Repair-TurboPriority([string]$Name) {
    if (-not $script:TurboApplyPriority -or -not (Test-Path -LiteralPath $SessionFile)) { return }
    try { $saved = Get-Content -Raw -LiteralPath $SessionFile | ConvertFrom-Json } catch { Write-Log 'estado da sessão inválido; watcher de prioridade suspenso' 'WARN'; return }
    foreach ($savedProcess in @($saved.Processes)) {
        $p = Get-Process -Id ([int]$savedProcess.Id) -ErrorAction SilentlyContinue
        if (-not (Test-ProcessIdentity $savedProcess $p)) { continue }
        try {
            if ([string]$p.PriorityClass -ne 'AboveNormal') {
                $p.PriorityClass = [Diagnostics.ProcessPriorityClass]::AboveNormal
                Write-Log "watcher reaplicou AboveNormal no PID $($p.Id)"
            }
        } catch { Write-Log "watcher não conseguiu verificar PID $($savedProcess.Id): $($_.Exception.Message)" 'WARN' }
    }
}

function Get-SafeBackgroundProcesses {
    $names = @('Spotify','Discord','msedge','chrome','EpicGamesLauncher','OneDrive','AdobeCollabSync','EABackgroundService')
    @(Get-Process -Name $names -ErrorAction SilentlyContinue | Sort-Object Id -Unique)
}

function Save-Session([object[]]$Processes, [string]$Scheme, [string]$CreatedScheme, [object[]]$ClosedBackground) {
    $state = [pscustomobject]@{
        Created = (Get-Date).ToString('o')
        SessionId = $SessionId
        User = [Environment]::UserName
        Computer = $env:COMPUTERNAME
        Windows = [string](Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Caption)
        Profile = $Profile
        Game = $GameExe
        GamePath = $script:GameResolvedPath
        Scheme = $Scheme
        CreatedScheme = $CreatedScheme
        Processes = @($Processes)
        ClosedBackground = @($ClosedBackground)
    }
    $state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $SessionFile -Encoding UTF8
    $state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $LastSession -Encoding UTF8
}

function Get-ProcessIdentity([System.Diagnostics.Process]$Process) {
    $path = $null
    $affinity = $null
    try { $path = $Process.MainModule.FileName } catch {
        try { $path = $Process.Path } catch {}
    }
    try { $affinity = $Process.ProcessorAffinity.ToInt64() } catch {}
    [pscustomobject]@{
        Id = $Process.Id
        Name = $Process.ProcessName
        Path = $path
        Priority = [string]$Process.PriorityClass
        Affinity = $affinity
    }
}

function Test-ProcessIdentity([object]$Saved, [System.Diagnostics.Process]$Current) {
    if (-not $Current) { return $false }
    if ([int]$Saved.Id -ne $Current.Id) { return $false }
    if ($Saved.Name -and ([string]$Saved.Name -ine [string]$Current.ProcessName)) { return $false }
    if ($Saved.Path) {
        $currentPath = $null
        try { $currentPath = $Current.MainModule.FileName } catch {
            try { $currentPath = $Current.Path } catch {}
        }
        if (-not $currentPath) { return $false }
        if (-not ([IO.Path]::GetFullPath($currentPath) -ieq [IO.Path]::GetFullPath([string]$Saved.Path))) {
            return $false
        }
    }
    return $true
}

function Get-AvailableDiskSummary {
    $disks = @()
    try {
        $disks = @(Get-PhysicalDisk -ErrorAction Stop | ForEach-Object {
            [pscustomobject]@{
                Name = $_.FriendlyName
                MediaType = [string]$_.MediaType
                BusType = [string]$_.BusType
                Health = [string]$_.HealthStatus
            }
        })
    } catch {}
    if (-not $disks.Count) {
        try {
            $disks = @(Get-CimInstance Win32_DiskDrive -ErrorAction Stop | ForEach-Object {
                [pscustomobject]@{
                    Name = $_.Model
                    MediaType = if ([string]$_.Model -match '(?i)nvme|ssd') { 'SSD' } else { 'HDD/unknown' }
                    BusType = [string]$_.InterfaceType
                    Health = 'unknown'
                }
            })
        } catch {}
    }
    return $disks
}

function Get-HealthCheck {
    $checks = New-Object System.Collections.Generic.List[object]
    $windows = ($env:OS -eq 'Windows_NT')
    $checks.Add([pscustomobject]@{ Name='windows_supported'; Status=if ($windows) { 'ok' } else { 'failed' }; Critical=$true; Detail=$env:OS })
    $psOk = ($PSVersionTable.PSVersion.Major -ge 5)
    $checks.Add([pscustomobject]@{ Name='powershell'; Status=if ($psOk) { 'ok' } else { 'failed' }; Critical=$true; Detail=$PSVersionTable.PSVersion.ToString() })
    foreach ($command in @('powercfg.exe','Get-CimInstance','Get-Process')) {
        $available = [bool](Get-Command $command -ErrorAction SilentlyContinue)
        $checks.Add([pscustomobject]@{ Name=("dependency_{0}" -f $command); Status=if ($available) { 'ok' } else { 'failed' }; Critical=$true; Detail=if ($available) { 'available' } else { 'missing' } })
    }
    $admin = $false
    try { $admin = Test-Administrator } catch {}
    $checks.Add([pscustomobject]@{ Name='admin'; Status=if ($admin) { 'ok' } else { 'warning' }; Critical=$false; Detail=if ($admin) { 'elevated' } else { 'not elevated' } })
    $scheme = $null
    try { $scheme = Get-ActiveScheme } catch {}
    $checks.Add([pscustomobject]@{ Name='power_plan'; Status=if ($scheme) { 'ok' } else { 'warning' }; Critical=$false; Detail=if ($scheme) { $scheme } else { 'not detected' } })
    $rootDrive = [IO.Path]::GetPathRoot($Root)
    try {
        $drive = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $rootDrive.TrimEnd('\')) -ErrorAction Stop
        $freeGb = [math]::Round([double]$drive.FreeSpace / 1GB, 1)
        $checks.Add([pscustomobject]@{ Name='disk_space'; Status=if ($freeGb -ge 2) { 'ok' } else { 'failed' }; Critical=$true; Detail=("{0} GB free" -f $freeGb) })
    } catch {
        $checks.Add([pscustomobject]@{ Name='disk_space'; Status='warning'; Critical=$false; Detail='not available' })
    }
    $snapshotOk = $true
    try { New-Item -ItemType File -Force -Path (Join-Path $Data 'state\health_probe.tmp') | Remove-Item -Force } catch { $snapshotOk = $false }
    $checks.Add([pscustomobject]@{ Name='snapshot_write'; Status=if ($snapshotOk) { 'ok' } else { 'failed' }; Critical=$true; Detail=if ($snapshotOk) { 'state directory writable' } else { 'state directory is not writable' } })
    $failed = @($checks | Where-Object { $_.Critical -and $_.Status -eq 'failed' })
    [pscustomobject]@{
        Timestamp = (Get-Date).ToString('o')
        Checks = @($checks)
        CriticalFailures = @($failed.Name)
        Ready = ($failed.Count -eq 0)
    }
}

function Write-HealthReport([object]$Health) {
    $path = Join-Path $Data ('reports\health_{0}.json' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    $Health | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $path -Encoding UTF8
    if ($JsonOutput) {
        $Health | ConvertTo-Json -Depth 12 | Write-Output
    } else {
        foreach ($check in $Health.Checks) {
            Write-Host ("{0,-24} {1,-8} {2}" -f $check.Name, $check.Status, $check.Detail)
        }
    }
    Write-Host ("health_ready={0} report={1}" -f $Health.Ready, $path)
    return $path
}

function Restore-Session {
    if (-not (Test-Path -LiteralPath $SessionFile) -and -not (Test-Path -LiteralPath $LastSession)) {
        throw 'nenhum estado de sessao encontrado'
    }
    $file = if (Test-Path -LiteralPath $SessionFile) { $SessionFile } else { $LastSession }
    $state = Get-Content -Raw -LiteralPath $file | ConvertFrom-Json
    try { Invoke-AdaptiveSessionActions 'restore' ([string]$state.Bottleneck) } catch { Write-Log "restore adaptativo falhou: $($_.Exception.Message)" 'WARN' }
    if (-not $DryRun -and $state.Scheme) {
        & powercfg.exe /setactive $state.Scheme 2>&1 | ForEach-Object { Write-Log ([string]$_) }
    }
    foreach ($pstate in @($state.Processes)) {
        $p = Get-Process -Id ([int]$pstate.Id) -ErrorAction SilentlyContinue
        if (-not (Test-ProcessIdentity $pstate $p)) {
            if ($p) { Write-Log "PID $($pstate.Id) foi reutilizado por outro executavel; processo ignorado" 'WARN' }
            continue
        }
        try { $p.PriorityClass = [Diagnostics.ProcessPriorityClass]([string]$pstate.Priority) } catch { Write-Log "falha ao restaurar prioridade do PID $($pstate.Id): $($_.Exception.Message)" 'WARN' }
        if ($null -ne $pstate.Affinity -and -not $DryRun) {
            try { $p.ProcessorAffinity = [IntPtr]([int64]$pstate.Affinity) } catch { Write-Log "falha ao restaurar afinidade do PID $($pstate.Id)" 'WARN' }
        }
    }
    $closedItems = @($state.ClosedBackground | Where-Object { $_ })
    if ($closedItems.Count -and (Confirm-Action 'Reabrir os aplicativos fechados temporariamente?')) {
        foreach ($closed in $closedItems) {
            if ($closed.Path -and (Test-Path -LiteralPath $closed.Path) -and -not $DryRun) {
                Start-Process -FilePath $closed.Path -ErrorAction SilentlyContinue | Out-Null
                Write-Log "aplicativo reaberto: $($closed.Name)"
            }
        }
    }
    if ($state.CreatedScheme -and $state.CreatedScheme -ne $state.Scheme -and -not $DryRun) {
        & powercfg.exe /delete $state.CreatedScheme 2>$null
    }
    $checks = New-Object System.Collections.Generic.List[object]
    if ($state.Scheme) {
        $actualScheme = Get-ActiveScheme
        $checks.Add([pscustomobject]@{ Item='power_scheme'; Expected=$state.Scheme; Actual=$actualScheme; Status=if ($actualScheme -eq $state.Scheme -or $DryRun) { 'ok' } else { 'failed' } })
    }
    foreach ($pstate in @($state.Processes)) {
        $p = Get-Process -Id ([int]$pstate.Id) -ErrorAction SilentlyContinue
        if (-not (Test-ProcessIdentity $pstate $p)) {
            $checks.Add([pscustomobject]@{ Item=("process_{0}" -f $pstate.Id); Expected=$pstate.Priority; Actual='not_running'; Status='not_verifiable' })
            continue
        }
        $priorityOk = ([string]$p.PriorityClass -eq [string]$pstate.Priority) -or $DryRun
        $affinityOk = $true
        if ($null -ne $pstate.Affinity) {
            try { $affinityOk = ($p.ProcessorAffinity.ToInt64() -eq [int64]$pstate.Affinity) -or $DryRun } catch { $affinityOk = $false }
        }
        $checks.Add([pscustomobject]@{ Item=("process_{0}" -f $pstate.Id); Expected=$pstate.Priority; Actual=[string]$p.PriorityClass; Status=if ($priorityOk -and $affinityOk) { 'ok' } else { 'failed' } })
    }
    $verifyPath = Join-Path $Data ('reports\rollback_verify_{0}.json' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    $checks | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $verifyPath -Encoding UTF8
    if (@($checks | Where-Object Status -eq 'failed').Count) { Write-Log "rollback concluido com verificacao falha: $verifyPath" 'WARN' } else { Write-Log "rollback verificado: $verifyPath" }
    Remove-Item -LiteralPath $SessionFile -Force -ErrorAction SilentlyContinue
    Release-SessionLock
    Write-Log 'sessao restaurada'
}

function Start-Session {
    if ($Profile -eq 'competitive' -and -not (Test-Administrator)) {
        throw 'o perfil competitivo requer administrador para a opcao de plano de energia'
    }
    $name = Resolve-GameName
    if (-not $name) { throw 'executavel do jogo nao informado' }
    $procs = Get-GameProcesses $name
    if (-not $procs) {
        if ($Silent) { throw "processo '$name' nao encontrado" }
        Write-Host "Abra o jogo agora. aguardando ate 30 segundos..."
        1..30 | ForEach-Object {
            Start-Sleep -Seconds 1
            if (-not $procs) { $procs = Get-GameProcesses $name }
        }
    }
    if (-not $procs) { throw "processo '$name' nao encontrado" }
    $oldScheme = Get-ActiveScheme
    $createdScheme = $null
    $snap = @($procs | ForEach-Object { Get-ProcessIdentity $_ } | Sort-Object Id -Unique)
    $closed = @()
    if ($CloseBackground) {
        $bg = @(Get-SafeBackgroundProcesses | Where-Object { $_.Id -notin @($procs.Id) })
        if ($bg.Count -and (Confirm-Action ("Fechar temporariamente: " + (($bg | Select-Object -ExpandProperty ProcessName -Unique) -join ', ') + '?'))) {
            foreach ($p in $bg) {
                $path = $null
                try { $path = $p.Path } catch {}
                if (-not $DryRun) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
                Write-Log "background encerrado temporariamente: $($p.ProcessName) PID $($p.Id)"
                $closed += [pscustomobject]@{ Name=$p.ProcessName; Path=$path }
            }
        }
    }
    if (-not (Confirm-Action "Aplicar perfil $Profile ao processo $name")) { Write-Log 'operacao cancelada'; return }
    Acquire-SessionLock
    Save-Session $snap $oldScheme $createdScheme $closed
    foreach ($p in $procs) {
        if ($script:TurboApplyPriority -or $Action -ne 'turbo') {
            if (-not $DryRun) {
                try { $p.PriorityClass = [Diagnostics.ProcessPriorityClass]$Priority } catch { Write-Log "prioridade falhou no PID $($p.Id): $($_.Exception.Message)" 'WARN' }
            }
            Write-Log "prioridade $Priority solicitada para $($p.ProcessName) PID $($p.Id)"
        } else {
            Write-Log "perfil seguro sem mudança: não há evidência suficiente para alterar prioridade"
        }
    }
    if ($Profile -eq 'competitive' -and (Confirm-Action 'Ativar plano Ultimate Performance? Em notebook use somente na tomada')) {
        if (-not $DryRun) {
            $out = & powercfg.exe /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1 | Out-String
            $m = [regex]::Match($out, '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}')
            if ($m.Success) {
                $createdScheme = $m.Value
                & powercfg.exe /setactive $createdScheme | Out-Null
                Save-Session $snap $oldScheme $createdScheme $closed
            } else { Write-Log 'Ultimate Performance nao foi criado; plano anterior preservado' 'WARN' }
        }
    }
    Write-Log "sessao iniciada: jogo=$name perfil=$Profile"
}

function Get-GameLibraries {
    $items = New-Object System.Collections.Generic.List[object]
    $steamRoots = @()
    $steamVdf = Join-Path ${env:ProgramFiles(x86)} 'Steam\steamapps\libraryfolders.vdf'
    if (Test-Path $steamVdf) {
        $content = Get-Content -Raw -LiteralPath $steamVdf
        foreach ($m in [regex]::Matches($content, '"path"\s+"([^"]+)"')) {
            $steamRoots += $m.Groups[1].Value.Replace('\\','\')
        }
    }
    foreach ($root in ($steamRoots | Select-Object -Unique)) {
        $common = Join-Path $root 'steamapps\common'
        if (Test-Path $common) {
            Get-ChildItem -Directory -LiteralPath $common -ErrorAction SilentlyContinue | ForEach-Object {
                $items.Add([pscustomobject]@{ Source='Steam'; Name=$_.Name; Path=$_.FullName })
            }
        }
    }
    $epic = Join-Path ${env:ProgramData} 'Epic\EpicGamesLauncher\Data\Manifests'
    if (Test-Path $epic) {
        Get-ChildItem -Filter '*.item' -LiteralPath $epic -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                $j = Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json
                if ($j.InstallLocation) { $items.Add([pscustomobject]@{ Source='Epic'; Name=$j.DisplayName; Path=$j.InstallLocation }) }
            } catch {}
        }
    }
    $items | Sort-Object Source,Name -Unique | Format-Table -AutoSize | Out-String | Write-Output
    $out = Join-Path $Data ('reports\game_libraries_{0}.csv' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    $items | Sort-Object Source,Name -Unique | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath $out
    Write-Log "bibliotecas exportadas: $out"
}

function Get-ThermalCorrelation {
    $seconds = [Math]::Max(5, [Math]::Min($TelemetrySeconds, 300))
    $rows = New-Object System.Collections.Generic.List[object]
    Write-Log "coletando telemetria por $seconds segundos"
    for ($i = 0; $i -lt $seconds; $i++) {
        $cpu = $null; $freq = $null; $gpu = $null
        try { $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue } catch {}
        try { $freq = (Get-Counter '\Processor Information(_Total)\Processor Frequency').CounterSamples[0].CookedValue } catch {}
        try {
            $samples = @(Get-Counter '\GPU Engine(*)\Utilization Percentage').CounterSamples
            if ($samples.Count) { $gpu = ($samples | Measure-Object CookedValue -Maximum).Maximum }
        } catch {}
        $temp = $null
        try {
            $zones = @(Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop)
            if ($zones) { $temp = (($zones | Measure-Object CurrentTemperature -Average).Average / 10) - 273.15 }
        } catch {}
        $rows.Add([pscustomobject]@{ Timestamp=(Get-Date).ToString('o'); CpuPercent=$cpu; GpuEngineMaxPercent=$gpu; CpuFrequencyCounter=$freq; AcpiTemperatureC=$temp })
        Start-Sleep -Seconds 1
    }
    $out = Join-Path $Data ('benchmarks\thermal_correlation_{0}.csv' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    $rows | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath $out
    $validTemp = @($rows | Where-Object { $null -ne $_.AcpiTemperatureC })
    $hot = $validTemp | Measure-Object AcpiTemperatureC -Maximum
    $lowClock = $rows | Where-Object { $null -ne $_.CpuFrequencyCounter } | Measure-Object CpuFrequencyCounter -Minimum
    Write-Host "arquivo: $out"
    if ($validTemp.Count) { Write-Host ("temperatura ACPI maxima: {0:N1} C" -f $hot.Maximum) } else { Write-Host 'sensor ACPI indisponivel; use HWiNFO/MSI Afterburner para temperatura de GPU.' }
    if ($lowClock.Count) { Write-Host ("menor contador de frequencia CPU: {0:N0} MHz" -f $lowClock.Minimum) }
    Write-Host 'correlacao conclusiva exige clock, temperatura e carga do mesmo componente no mesmo intervalo.'
}

function Get-BottleneckEstimate {
    $cpuRows = @(); $gpuRows = @()
    1..5 | ForEach-Object {
        try { $cpuRows += (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue } catch {}
        try {
            $s = @(Get-Counter '\GPU Engine(*)\Utilization Percentage').CounterSamples
            if ($s.Count) { $gpuRows += ($s | Measure-Object CookedValue -Maximum).Maximum }
        } catch {}
        Start-Sleep -Milliseconds 500
    }
    $cpu = if ($cpuRows) { ($cpuRows | Measure-Object -Average).Average } else { $null }
    $gpu = if ($gpuRows) { ($gpuRows | Measure-Object -Average).Average } else { $null }
    $hint = if ($null -eq $cpu -or $null -eq $gpu) { 'dados insuficientes' }
        elseif ($cpu -ge 85 -and $gpu -lt 85) { 'CPU-bound provavel' }
        elseif ($gpu -ge 85 -and $cpu -lt 85) { 'GPU-bound provavel' }
        elseif ($cpu -ge 85 -and $gpu -ge 85) { 'carga mista; limitar FPS pode estabilizar frametime' }
        else { 'nenhum gargalo dominante neste intervalo' }
    [pscustomobject]@{ CpuAverage=[math]::Round($cpu,1); GpuEngineMaxAverage=[math]::Round($gpu,1); Conclusion=$hint } | Format-List
}

function Test-Prerequisites {
    if ($env:OS -ne 'Windows_NT') { throw 'NaveBoost so pode executar no Windows' }
    if ($PSVersionTable.PSVersion.Major -lt 5) { throw 'PowerShell 5.1 ou superior e necessario' }
    foreach ($command in @('powercfg.exe','Get-CimInstance','Get-Process')) {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) { throw "dependencia ausente: $command" }
    }
    if ($Profile -eq 'competitive' -and -not (Test-Administrator)) {
        throw 'o perfil competitivo precisa de administrador para criar plano temporario'
    }
}

function Invoke-AdaptiveScan {
    $health = Get-HealthCheck
    $healthPath = Write-HealthReport $health
    if (-not $health.Ready) {
        Write-Log 'health check bloqueou o Turbo; nenhuma alteração foi aplicada' 'ERROR'
        return [pscustomobject]@{ Stage='HEALTH'; Health=$health; Ready=$false; Report=$healthPath }
    }
    $name = Resolve-GameName
    if (-not $name) { throw 'executavel do jogo nao informado' }
    $hardware = Get-HardwareSummary
    $telemetry = Get-SystemTelemetry $name
    $bottleneck = Classify-Bottleneck $telemetry
    $plan = Get-SafeAdaptivePlan $bottleneck.Class $hardware
    $learning = Read-GameLearning $name $hardware
    $result = [pscustomobject]@{
        Stage='SCAN -> HARDWARE CLASS -> BOTTLENECK -> SAFE PROFILE'
        Timestamp=(Get-Date).ToString('o')
        Game=$name
        Health=$health
        Hardware=$hardware
        Telemetry=$telemetry
        Bottleneck=$bottleneck
        Plan=$plan
        HistoricalBestProfile=$learning.BestProfile
        Report=$healthPath
    }
    $path = Join-Path $Data ('reports\adaptive_scan_{0}.json' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    $result | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $path -Encoding UTF8
    Write-Host ("class={0} confidence={1}% profile={2} safety={3}" -f $bottleneck.Class, $bottleneck.Confidence, $plan.Profile, $plan.Safety)
    Write-Host ("reason={0}" -f $bottleneck.Reason)
    Write-Host ("scan_report={0}" -f $path)
    if ($JsonOutput) { $result | ConvertTo-Json -Depth 12 | Write-Output }
    return $result
}

function Invoke-BenchmarkComparison {
    if (-not $BaselineCsv -or -not $PostCsv) { throw 'benchmark requer -BaselineCsv e -PostCsv' }
    $result = Compare-Benchmarks $BaselineCsv $PostCsv
    $path = Join-Path $Data ('benchmarks\comparison_{0}.json' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    $result | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $path -Encoding UTF8
    $result.Metrics | Format-Table Name,Before,After,DeltaPercent -AutoSize
    Write-Host ("score={0} margin={1} decision={2} report={3}" -f $result.Score, $result.Margin, $result.Decision, $path)
    Write-Host ("ganho medido: {0:N2}% (somente com benchmark válido)" -f ($result.Metrics | Where-Object Name -eq 'FPS médio' | Select-Object -First 1 -ExpandProperty DeltaPercent))
    if ($JsonOutput) { $result | ConvertTo-Json -Depth 12 | Write-Output }
    if ($GameExe) { Save-GameLearning ([IO.Path]::GetFileNameWithoutExtension($GameExe)) $Profile $result $result.Decision $null }
    return $result
}

function Invoke-Report {
    $scan = Get-ChildItem -LiteralPath (Join-Path $Data 'reports') -Filter 'adaptive_scan_*.json' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $decision = Get-ChildItem -LiteralPath (Join-Path $Data 'benchmarks') -Filter 'comparison_*.json' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $scan) { throw 'nenhum adaptive scan encontrado para gerar relatório' }
    $scanData = Get-Content -Raw -LiteralPath $scan.FullName | ConvertFrom-Json
    $decisionData = if ($decision) { Get-Content -Raw -LiteralPath $decision.FullName | ConvertFrom-Json } else { $null }
    Write-HtmlReport $decisionData $scanData.Hardware $scanData.Bottleneck $scanData.Plan ([pscustomobject]@{ Status='see active_session or rollback verification report' })
}

function Get-ProtectionDiagnostics {
    $thirdParty = @()
    try {
        $thirdParty = @(Get-CimInstance -Namespace root\SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction Stop |
            Where-Object { $_.displayName -notmatch '(?i)microsoft defender|windows defender' } |
            ForEach-Object {
                [pscustomobject]@{
                    Name = $_.displayName
                    ProductState = $_.productState
                    RealtimeProtection = 'unknown; SecurityCenter2 does not expose a stable portable boolean'
                }
            })
    } catch {}
    $antiCheatNames = 'vgc','vgk','EasyAntiCheat','EasyAntiCheat_EOS','BEService','BEDaisy','Ricochet','RiotClientServices'
    $processes = @()
    foreach ($n in $antiCheatNames) {
        $processes += @(Get-Process -Name $n -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ProcessName -Unique)
    }
    $drivers = @()
    try {
        $drivers = @(Get-CimInstance Win32_SystemDriver -ErrorAction Stop |
            Where-Object { $_.Name -match '(?i)vgk|vgc|easyanticheat|battleeye|bedaisy|ricochet' } |
            Select-Object Name,DisplayName,State,StartMode)
    } catch {}
    [pscustomobject]@{
        ThirdPartyAntivirus = @($thirdParty)
        AntiCheatProcesses = @($processes | Select-Object -Unique)
        AntiCheatDrivers = @($drivers)
        CompetitiveModeBlocked = ($processes.Count -gt 0 -or $drivers.Count -gt 0)
        Note = 'anti-cheat e drivers de segurança são somente diagnóstico; nenhum processo/driver é alterado'
    }
}

function Get-MsiModeDiagnostics {
    $items = New-Object System.Collections.Generic.List[object]
    $rootKey = 'HKLM:\SYSTEM\CurrentControlSet\Enum\PCI'
    try {
        Get-ChildItem -LiteralPath $rootKey -Recurse -ErrorAction Stop |
            Where-Object { $_.PSChildName -eq 'MessageSignaledInterruptProperties' } |
            ForEach-Object {
                $p = Get-ItemProperty -LiteralPath $_.PSPath -Name MSISupported -ErrorAction SilentlyContinue
                if ($null -ne $p.MSISupported) {
                    $kind = if ($_.PSPath -match '(?i)ven_10de|ven_1002|ven_8086.*dev_.*3') { 'gpu-or-display' } else { 'pci-device' }
                    $items.Add([pscustomobject]@{ Path=$_.PSPath; DeviceClass=$kind; MSISupported=[int]$p.MSISupported })
                }
            }
    } catch {}
    [pscustomobject]@{
        Available = ($items.Count -gt 0)
        Devices = @($items)
        Changed = $false
        Note = 'MSI mode é leitura do registro; o NaveBoost não altera MSISupported automaticamente'
    }
}

function Get-MemoryPressure {
    $hardFaults = $null; $commit = $null; $pagefile = $null
    try { $hardFaults = [math]::Round((Get-Counter '\Memory\Pages/sec' -ErrorAction Stop).CounterSamples[0].CookedValue, 1) } catch {}
    try { $commit = [math]::Round((Get-Counter '\Memory\Committed Bytes In Use' -ErrorAction Stop).CounterSamples[0].CookedValue, 1) } catch {}
    try { $pagefile = [math]::Round((Get-Counter '\Paging File(_Total)\% Usage' -ErrorAction Stop).CounterSamples[0].CookedValue, 1) } catch {}
    [pscustomobject]@{
        HardFaultsPerSecond = $hardFaults
        CommitPercent = $commit
        PagefileUsagePercent = $pagefile
        Pressure = if ($hardFaults -ge 100 -or $commit -ge 90) { 'high' } elseif ($hardFaults -ge 20 -or $commit -ge 80) { 'elevated' } else { 'normal_or_unknown' }
    }
}

function Get-ProcessorTopology {
    $processors = @(Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue)
    $first = $processors | Select-Object -First 1
    [pscustomobject]@{
        Sockets = $processors.Count
        Cores = if ($first) { [int]$first.NumberOfCores } else { $null }
        LogicalProcessors = if ($first) { [int]$first.NumberOfLogicalProcessors } else { $null }
        HybridCoreType = 'unknown; Win32_Processor não expõe P-core/E-core de forma portátil'
        Numa = 'unknown'
        ProcessorGroups = 'unknown'
        AffinityRecommendation = 'recommend-only; nenhuma afinidade é forçada sem evidência A/B'
    }
}

function Get-HardwareSummary {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $gpu = @(Get-CimInstance Win32_VideoController)
    $ramGb = [math]::Round(([double]$os.TotalVisibleMemorySize / 1MB), 1)
    $computer = Get-CimInstance Win32_ComputerSystem
    $battery = @(Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Select-Object EstimatedChargeRemaining, BatteryStatus)
    $monitor = @(Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams -ErrorAction SilentlyContinue | Select-Object MaxHorizontalImageSize, MaxVerticalImageSize)
    $disk = Get-AvailableDiskSummary
    $dedicated = @($gpu | Where-Object { $_.AdapterRAM -and $_.PNPDeviceID -notmatch 'VEN_8086' })
    $integrated = @($gpu | Where-Object { $_.PNPDeviceID -match 'VEN_8086' })
    $architecture = if ([Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' }
    $vram = @($gpu | Where-Object AdapterRAM | ForEach-Object { [math]::Round(([double]$_.AdapterRAM / 1GB), 1) })
    $thermal = $null
    $refresh = $null
    try {
        $zones = @(Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop)
        if ($zones) { $thermal = [math]::Round((($zones | Measure-Object CurrentTemperature -Average).Average / 10) - 273.15, 1) }
    } catch {}
    try { $refresh = [int](Get-CimInstance Win32_VideoController | Select-Object -First 1 -ExpandProperty CurrentRefreshRate) } catch {}
    [pscustomobject]@{
        NaveBoostVersion = $NaveBoostVersion
        Windows = $os.Caption
        Build = $os.BuildNumber
        Architecture = $architecture
        Cpu = $cpu.Name
        CpuCores = [int]$cpu.NumberOfCores
        LogicalProcessors = [int]$cpu.NumberOfLogicalProcessors
        CurrentCpuMHz = [int]$cpu.CurrentClockSpeed
        MaxCpuMHz = [int]$cpu.MaxClockSpeed
        RamGb = $ramGb
        RamFreeGb = [math]::Round(([double]$os.FreePhysicalMemory / 1MB), 1)
        Gpus = @($gpu | ForEach-Object { $_.Name })
        DedicatedGpus = @($dedicated | ForEach-Object { $_.Name })
        IntegratedGpus = @($integrated | ForEach-Object { $_.Name })
        VramGb = if ($vram) { ($vram | Measure-Object -Maximum).Maximum } else { $null }
        Disks = $disk
        Battery = $battery
        ThermalC = $thermal
        Monitor = $monitor
        RefreshRateHz = $refresh
        ActivePowerScheme = Get-ActiveScheme
        ProcessorTopology = Get-ProcessorTopology
        Protection = Get-ProtectionDiagnostics
        MsiMode = Get-MsiModeDiagnostics
    }
}

function Get-ProcessGpuPercent([int]$Pid) {
    try {
        $samples = @(Get-Counter '\GPU Engine(*)\Utilization Percentage' -ErrorAction Stop).CounterSamples
        $mine = @($samples | Where-Object { $_.InstanceName -match ("pid_{0}(_|$)" -f $Pid) })
        if ($mine.Count) { return [math]::Min(100, [math]::Round((($mine | Measure-Object CookedValue -Maximum).Maximum), 1)) }
    } catch {}
    return $null
}

function Get-ProcessTelemetry([string]$Name) {
    $p0 = Get-Process -Name $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $p0) {
        return [pscustomobject]@{ Process=$Name; PID=$null; CpuPercent=$null; CpuPeakPercent=$null; GpuPercent=$null; GpuPeakPercent=$null; RamMb=$null; EffectiveCpuFrequencyPercent=$null; AcpiTemperatureC=$null; ThermalHint='processo ausente'; SampleCount=0 }
    }
    $pid = $p0.Id
    $logical = 1
    try { $logical = [math]::Max(1,[int](Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors) } catch {}
    $cpuSamples = New-Object System.Collections.Generic.List[double]
    $gpuSamples = New-Object System.Collections.Generic.List[double]
    $freqSamples = New-Object System.Collections.Generic.List[double]
    $tempSamples = New-Object System.Collections.Generic.List[double]
    $ramSamples = New-Object System.Collections.Generic.List[double]
    1..3 | ForEach-Object {
        $before = Get-Process -Id $pid -ErrorAction SilentlyContinue
        if (-not $before) { return }
        $cpuStart = $null
        try { $cpuStart = $before.TotalProcessorTime.TotalSeconds } catch {}
        $sw = [Diagnostics.Stopwatch]::StartNew()
        Start-Sleep -Milliseconds 750
        $after = Get-Process -Id $pid -ErrorAction SilentlyContinue
        $sw.Stop()
        if ($after -and $null -ne $cpuStart) {
            try {
                $delta = $after.TotalProcessorTime.TotalSeconds - $cpuStart
                $pct = [math]::Max(0,[math]::Min(100,($delta / [math]::Max(.1,$sw.Elapsed.TotalSeconds) / $logical) * 100))
                $cpuSamples.Add([double]$pct)
                $ramSamples.Add([double]([math]::Round($after.WorkingSet64 / 1MB, 0)))
            } catch {}
        }
        $gpu = Get-ProcessGpuPercent $pid
        if ($null -ne $gpu) { $gpuSamples.Add([double]$gpu) }
        try { $freqSamples.Add([double](Get-Counter '\Processor Information(_Total)\Processor Frequency').CounterSamples[0].CookedValue) } catch {}
        try {
            $zones = @(Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop)
            if ($zones) { $tempSamples.Add([double]((($zones | Measure-Object CurrentTemperature -Average).Average / 10) - 273.15)) }
        } catch {}
    }
    $cpuAvg = if ($cpuSamples.Count) { [math]::Round((($cpuSamples | Measure-Object -Average).Average),1) } else { $null }
    $gpuAvg = if ($gpuSamples.Count) { [math]::Round((($gpuSamples | Measure-Object -Average).Average),1) } else { $null }
    $freqAvg = if ($freqSamples.Count) { [math]::Round((($freqSamples | Measure-Object -Average).Average),1) } else { $null }
    $tempAvg = if ($tempSamples.Count) { [math]::Round((($tempSamples | Measure-Object -Average).Average),1) } else { $null }
    $cpuPeak = if ($cpuSamples.Count) { [math]::Round((($cpuSamples | Measure-Object -Maximum).Maximum),1) } else { $null }
    $gpuPeak = if ($gpuSamples.Count) { [math]::Round((($gpuSamples | Measure-Object -Maximum).Maximum),1) } else { $null }
    $ramAvg = if ($ramSamples.Count) { [math]::Round((($ramSamples | Measure-Object -Average).Average),0) } else { $null }
    $thermal = 'sem evidencia suficiente'
    if ($tempAvg -and $tempAvg -ge 90 -and $cpuAvg -and $cpuAvg -ge 70) {
        if ($freqAvg -and $freqAvg -le 85) { $thermal = 'forte indicio de throttling térmico' }
        else { $thermal = 'temperatura elevada; monitorar' }
    }
    [pscustomobject]@{
        Process=$Name
        PID=$pid
        CpuPercent=$cpuAvg
        CpuPeakPercent=$cpuPeak
        GpuPercent=$gpuAvg
        GpuPeakPercent=$gpuPeak
        RamMb=$ramAvg
        EffectiveCpuFrequencyPercent=$freqAvg
        AcpiTemperatureC=$tempAvg
        ThermalHint=$thermal
        SampleCount=$cpuSamples.Count
    }
}
function Get-SystemTelemetry([string]$Name) {
    $process = Get-ProcessTelemetry $Name
    $ram = $null
    $diskRows = New-Object System.Collections.Generic.List[double]
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $ram = [math]::Round((1 - ([double]$os.FreePhysicalMemory / [double]$os.TotalVisibleMemorySize)) * 100, 1)
    } catch {}
    1..3 | ForEach-Object {
        try { $diskRows.Add([double](Get-Counter '\PhysicalDisk(_Total)\% Disk Time').CounterSamples[0].CookedValue) } catch {}
        Start-Sleep -Milliseconds 250
    }
    $diskBusy = if ($diskRows.Count) { [math]::Round((($diskRows | Measure-Object -Average).Average),1) } else { $null }
    [pscustomobject]@{
        Process = $process
        RamUsedPercent = $ram
        MemoryPressure = Get-MemoryPressure
        DiskBusyPercent = $diskBusy
        DiskPeakPercent = if ($diskRows.Count) { [math]::Round((($diskRows | Measure-Object -Maximum).Maximum),1) } else { $null }
        Timestamp = (Get-Date).ToString('o')
    }
}
function Classify-Bottleneck([object]$Telemetry) {
    $p = $Telemetry.Process
    $cpu = if ($null -ne $p.CpuPercent) { [double]$p.CpuPercent } else { $null }
    $gpu = if ($null -ne $p.GpuPercent) { [double]$p.GpuPercent } else { $null }
    $ram = if ($null -ne $Telemetry.RamUsedPercent) { [double]$Telemetry.RamUsedPercent } else { $null }
    $disk = if ($null -ne $Telemetry.DiskBusyPercent) { [double]$Telemetry.DiskBusyPercent } else { $null }
    $temp = if ($null -ne $p.AcpiTemperatureC) { [double]$p.AcpiTemperatureC } else { $null }
    $freq = if ($null -ne $p.EffectiveCpuFrequencyPercent) { [double]$p.EffectiveCpuFrequencyPercent } else { $null }
    $memoryPressure = $Telemetry.MemoryPressure
    $classification = 'balanced'
    $confidence = 0
    $reason = 'nenhuma métrica dominante na amostra'
    if ($memoryPressure -and ($memoryPressure.Pressure -eq 'high' -or [double]$memoryPressure.HardFaultsPerSecond -ge 100)) {
        $classification = 'ram_bound'; $confidence = 90; $reason = 'hard page faults/commit indicam pressão de memória real; RAM livre isoladamente não foi usada'
    } elseif ($temp -and $temp -ge 90 -and $cpu -and $cpu -ge 70 -and ($null -eq $freq -or $freq -le 85)) {
        $classification = 'thermal_bound'; $confidence = if ($freq) { 92 } else { 78 }; $reason = 'temperatura elevada combinada com carga de CPU e indício de redução de frequência'
    } elseif ($ram -and $ram -ge 90) {
        $classification = 'ram_bound'; $confidence = [math]::Round([math]::Min(97,72 + (($ram - 90) * 5)),0); $reason = 'memória física próxima da saturação'
    } elseif ($disk -and $disk -ge 90 -and (-not $cpu -or $cpu -lt 90) -and (-not $gpu -or $gpu -lt 90)) {
        $classification = 'io_bound'; $confidence = [math]::Round([math]::Min(94,70 + (($disk - 90) * 4)),0); $reason = 'atividade de disco sustentada e sem saturação equivalente de CPU/GPU'
    } elseif ($cpu -and $gpu -and $cpu -ge 80 -and $cpu -ge ($gpu + 12)) {
        $classification = 'cpu_bound'; $confidence = [math]::Round([math]::Min(96,70 + (($cpu - $gpu) * 1.5) + (($cpu - 80) * .5)),0); $reason = 'CPU do processo elevada e claramente acima da utilização GPU observada'
    } elseif ($gpu -and $cpu -and $gpu -ge 85 -and $gpu -ge ($cpu + 8)) {
        $classification = 'gpu_bound'; $confidence = [math]::Round([math]::Min(96,72 + (($gpu - $cpu) * 1.5)),0); $reason = 'GPU do processo elevada e claramente acima da utilização CPU observada'
    } elseif ($cpu -and $cpu -ge 92 -and (-not $gpu -or $gpu -lt 75)) {
        $classification = 'cpu_bound'; $confidence = 82; $reason = 'CPU do processo muito elevada sem saturação equivalente de GPU'
    } elseif ($gpu -and $gpu -ge 92 -and (-not $cpu -or $cpu -lt 82)) {
        $classification = 'gpu_bound'; $confidence = 84; $reason = 'GPU do processo muito elevada sem saturação equivalente de CPU'
    } elseif ($null -eq $cpu -and $null -eq $gpu -and $null -eq $ram -and $null -eq $disk) {
        $classification = 'unknown'; $reason = 'contadores de desempenho indisponíveis'
    }
    [pscustomobject]@{
        Class = $classification
        Confidence = $confidence
        Reason = $reason
        CpuPercent = $cpu
        CpuPeakPercent = $p.CpuPeakPercent
        GpuPercent = $gpu
        GpuPeakPercent = $p.GpuPeakPercent
        RamUsedPercent = $ram
        DiskBusyPercent = $disk
        DiskPeakPercent = $Telemetry.DiskPeakPercent
        MemoryPressure = $memoryPressure
        TemperatureC = $temp
        CpuFrequencyPercent = $freq
        Samples = $p.SampleCount
    }
}
function Get-SafeAdaptivePlan([string]$Bottleneck, [object]$Hardware) {
    $applyPriority = $false
    $profile = 'safe'
    $changes = New-Object System.Collections.Generic.List[string]
    $blockedByAntiCheat = $Hardware.Protection -and $Hardware.Protection.CompetitiveModeBlocked
    switch ($Bottleneck) {
        'cpu_bound' {
            $applyPriority = (-not $blockedByAntiCheat)
            $changes.Add('prioridade abovenormal, reversível por sessão')
            $changes.Add('afinidade: somente recomendação até existir benchmark A/B')
            if ($blockedByAntiCheat) { $changes.Add('bloqueado: anti-cheat detectado; diagnóstico-only') }
        }
        'ram_bound' { $profile = 'low-end'; $changes.Add('nenhuma alteração automática; reduzir carga em segundo plano somente com confirmação') }
        'gpu_bound' { $profile = 'quality'; $changes.Add('nenhuma alteração automática; preservar estabilidade da GPU') }
        'io_bound' { $profile = 'low-latency'; $changes.Add('nenhuma alteração automática; não alterar cache/pagefile sem evidência') }
        'thermal_bound' { $profile = 'low-end'; $changes.Add('nenhuma alteração automática; priorizar temperatura e estabilidade') }
        'balanced' { $changes.Add('nenhuma alteração: não há evidência suficiente') }
        default { $changes.Add('nenhuma alteração: dados insuficientes') }
    }
    [pscustomobject]@{
        Profile=$profile
        Safety=if ($blockedByAntiCheat) { 'DIAGNOSTIC_ONLY' } else { 'SAFE' }
        ApplyPriority=$applyPriority
        Experimental=$false
        Changes=@($changes)
        HardwareClass=if ($Hardware.RamGb -le 8 -or $Hardware.LogicalProcessors -le 4) { 'low-end' } else { 'standard' }
        OptionalActions=@('HAGS A/B somente experimental','indexação por volume somente em io_bound','core parking somente em cpu_bound com snapshot')
    }
}
function Get-HardwareFingerprint([object]$Hardware) {
    $raw = @($Hardware.Windows,$Hardware.Build,$Hardware.Cpu,$Hardware.CpuCores,$Hardware.LogicalProcessors,$Hardware.RamGb,(($Hardware.Gpus | Sort-Object) -join '|'),$Hardware.VramGb,$Hardware.RefreshRateHz) -join '||'
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($raw))).Replace('-','')).ToLowerInvariant() } finally { $sha.Dispose() }
}

function Get-GameLearningPath([string]$Name) {
    $safeName = ($Name -replace '[^a-zA-Z0-9_.-]', '_')
    return (Join-Path $Data ("profiles\{0}.json" -f $safeName))
}

function Read-GameLearning([string]$Name, [object]$Hardware = $null) {
    $path = Get-GameLearningPath $Name
    if (Test-Path -LiteralPath $path) {
        try {
            $saved = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
            if ($Hardware -and $saved.HardwareFingerprint -and $saved.HardwareFingerprint -ne (Get-HardwareFingerprint $Hardware)) {
                Write-Log "histórico ignorado: hardware diferente" 'INFO'
                return [pscustomobject]@{ Executable=$Name; History=@(); BestProfile=$null; BestScore=$null; HardwareFingerprint=(Get-HardwareFingerprint $Hardware) }
            }
            return $saved
        } catch { Write-Log "perfil histórico inválido: $path" 'WARN' }
    }
    return [pscustomobject]@{ Executable=$Name; History=@(); BestProfile=$null; BestScore=$null; HardwareFingerprint=if ($Hardware) { Get-HardwareFingerprint $Hardware } else { $null } }
}

function Save-GameLearning([string]$Name, [string]$ProfileName, [object]$Benchmark, [string]$Decision, [object]$Hardware = $null) {
    $path = Get-GameLearningPath $Name
    $learning = Read-GameLearning $Name $Hardware
    $history = @($learning.History) + @([pscustomobject]@{
        Timestamp=(Get-Date).ToString('o')
        Profile=$ProfileName
        Decision=$Decision
        Score=$Benchmark.Score
        Metrics=$Benchmark.Metrics
    })
    $best = @($history | Where-Object { $_.Score -ne $null -and $_.Decision -eq 'KEEP' } | Sort-Object { [double]$_.Score } -Descending | Select-Object -First 1)
    [pscustomobject]@{
        Executable=$Name
        Updated=(Get-Date).ToString('o')
        HardwareFingerprint=if ($Hardware) { Get-HardwareFingerprint $Hardware } else { $learning.HardwareFingerprint }
        History=@($history | Select-Object -Last 20)
        BestProfile=if ($best) { $best[0].Profile } else { $learning.BestProfile }
        BestScore=if ($best) { $best[0].Score } else { $learning.BestScore }
    } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $path -Encoding UTF8
    Write-Log "aprendizado salvo: $path"
}

function Get-StatisticMean([double[]]$Values) {
    if (-not $Values -or $Values.Count -eq 0) { return $null }
    return (($Values | Measure-Object -Average).Average)
}
function Get-StatisticStdDev([double[]]$Values) {
    if (-not $Values -or $Values.Count -lt 2) { return 0 }
    $avg = Get-StatisticMean $Values
    $sum = 0.0
    foreach ($v in $Values) { $sum += [math]::Pow(([double]$v - $avg), 2) }
    return [math]::Sqrt($sum / ($Values.Count - 1))
}
function Convert-LocalizedNumber([string]$Raw, [ref]$Value) {
    $text = ([string]$Raw).Trim().Replace([char]0xa0,'')
    if (-not $text) { return $false }
    if ($text.Contains(',') -and $text.Contains('.')) {
        if ($text.LastIndexOf(',') -gt $text.LastIndexOf('.')) {
            $text = $text.Replace('.','').Replace(',','.')
        } else {
            $text = $text.Replace(',','')
        }
    } elseif ($text.Contains(',')) {
        $text = $text.Replace(',','.')
    }
    return [double]::TryParse($text,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$Value)
}

function Get-BenchmarkRows([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "arquivo de benchmark não encontrado: $Path" }
    $firstLine = Get-Content -LiteralPath $Path -TotalCount 1
    if (-not $firstLine) { throw "arquivo de benchmark vazio: $Path" }
    $delimiter = if (($firstLine -split ';').Count -gt ($firstLine -split ',').Count) { ';' } else { ',' }
    try {
        return @(Get-Content -LiteralPath $Path | ConvertFrom-Csv -Delimiter $delimiter)
    } catch {
        throw "CSV inválido em $Path (separador detectado: '$delimiter'): $($_.Exception.Message)"
    }
}

function Convert-BenchmarkRows([string]$Path) {
    $rows = @(Get-BenchmarkRows $Path)
    if ($rows.Count -lt $MinBenchmarkFrames) { throw "poucos frames em $Path (mínimo $MinBenchmarkFrames)" }
    $names = @($rows[0].PSObject.Properties.Name)
    $normalizedNames = @{}
    foreach ($name in $names) { $normalizedNames[($name -replace '[^a-z0-9]','').ToLowerInvariant()] = $name }
    $frameColumn = @('frametime','frametimems','msbetweenpresents','msbetweendisplaychange','frametime_ms') | ForEach-Object {
        $normalizedNames[$_]
    } | Where-Object { $_ } | Select-Object -First 1
    if (-not $frameColumn) {
        throw "coluna de frametime não encontrada em $Path. Use frametime, frametime_ms, MsBetweenPresents ou MsBetweenDisplayChange."
    }
    $ms = New-Object System.Collections.Generic.List[double]
    foreach ($row in $rows) {
        $value = 0.0
        $raw = [string]$row.$frameColumn
        if ((Convert-LocalizedNumber $raw ([ref]$value)) -and $value -gt 0 -and $value -lt 1000) { $ms.Add($value) }
    }
    if ($ms.Count -lt $MinBenchmarkFrames) { throw "frametimes válidos insuficientes em $Path (válidos=$($ms.Count), mínimo=$MinBenchmarkFrames)" }
    $fps = @($ms | ForEach-Object { 1000.0 / $_ })
    $sortedFps = @($fps | Sort-Object)
    $sortedMs = @($ms | Sort-Object)
    $oneCount = [math]::Max(1,[int][math]::Ceiling($fps.Count * .01))
    $zeroOneCount = [math]::Max(1,[int][math]::Ceiling($fps.Count * .001))
    $p99Index = [math]::Max(1,[int][math]::Ceiling($ms.Count * .99)) - 1
    $avgMs = Get-StatisticMean $ms
    $sdMs = Get-StatisticStdDev $ms
    $medianMs = if (($sortedMs.Count % 2) -eq 0) {
        ($sortedMs[($sortedMs.Count / 2) - 1] + $sortedMs[$sortedMs.Count / 2]) / 2
    } else {
        $sortedMs[[int][math]::Floor($sortedMs.Count / 2)]
    }
    [pscustomobject]@{
        Frames=$fps.Count
        AvgFps=[math]::Round((Get-StatisticMean $fps),2)
        Low1=[math]::Round((Get-StatisticMean @($sortedFps | Select-Object -First $oneCount)),2)
        Low01=if($fps.Count -ge 1000){[math]::Round((Get-StatisticMean @($sortedFps | Select-Object -First $zeroOneCount)),2)}else{$null}
        AvgFrameTimeMs=[math]::Round($avgMs,2)
        MedianFrameTimeMs=[math]::Round($medianMs,2)
        FrameTimeStdDevMs=[math]::Round($sdMs,3)
        FrameTimeCVPercent=if($avgMs -gt 0){[math]::Round(($sdMs/$avgMs)*100,2)}else{0}
        P99FrameTimeMs=[math]::Round($sortedMs[$p99Index],2)
        MaxFrameTimeMs=[math]::Round((($ms | Measure-Object -Maximum).Maximum),2)
    }
}

function Get-SafePercent([double]$Before, [double]$After) {
    if ($Before -eq 0) { return 0 }
    return [math]::Round((($After / $Before) - 1) * 100, 2)
}

function Compare-Benchmarks([string]$BeforePath, [string]$AfterPath) {
    $before = Convert-BenchmarkRows $BeforePath
    $after = Convert-BenchmarkRows $AfterPath
    $metrics = @(
        [pscustomobject]@{ Name='FPS médio'; Before=$before.AvgFps; After=$after.AvgFps; DeltaPercent=(Get-SafePercent $before.AvgFps $after.AvgFps); Weight=40; LowerIsBetter=$false },
        [pscustomobject]@{ Name='1% low'; Before=$before.Low1; After=$after.Low1; DeltaPercent=(Get-SafePercent $before.Low1 $after.Low1); Weight=25; LowerIsBetter=$false },
        [pscustomobject]@{ Name='0,1% low'; Before=$before.Low01; After=$after.Low01; DeltaPercent=if($null -ne $before.Low01 -and $null -ne $after.Low01){Get-SafePercent $before.Low01 $after.Low01}else{$null}; Weight=10; LowerIsBetter=$false },
        [pscustomobject]@{ Name='frametime P99'; Before=$before.P99FrameTimeMs; After=$after.P99FrameTimeMs; DeltaPercent=(Get-SafePercent $before.P99FrameTimeMs $after.P99FrameTimeMs); Weight=15; LowerIsBetter=$true },
        [pscustomobject]@{ Name='frametime CV'; Before=$before.FrameTimeCVPercent; After=$after.FrameTimeCVPercent; DeltaPercent=(Get-SafePercent $before.FrameTimeCVPercent $after.FrameTimeCVPercent); Weight=10; LowerIsBetter=$true }
    )
    $score = 0.0
    foreach ($metric in $metrics) {
        $direction = if ($metric.LowerIsBetter) { -1 } else { 1 }
        if ($null -ne $metric.DeltaPercent) { $score += ([double]$metric.DeltaPercent * $direction) * ([double]$metric.Weight / 100) }
    }
    $frameDeltaPercent = [math]::Round(([math]::Abs($after.Frames-$before.Frames) / [math]::Max(1,$before.Frames))*100,2)
    $qualityIssues = New-Object System.Collections.Generic.List[string]
    if ($frameDeltaPercent -gt 20) { $qualityIssues.Add("diferenca de frames $frameDeltaPercent%") }
    if ($after.FrameTimeCVPercent -gt ($before.FrameTimeCVPercent*1.25) -and ($after.FrameTimeCVPercent-$before.FrameTimeCVPercent) -gt 1) { $qualityIssues.Add('variabilidade do frametime aumentou muito') }
    if ($before.Frames -lt 1000 -or $after.Frames -lt 1000) { $qualityIssues.Add('0.1% low indisponível por baixa amostra') }
    $severeRegression = @($metrics | Where-Object { if ($null -eq $_.DeltaPercent) { $false } elseif ($_.LowerIsBetter) { $_.DeltaPercent -ge 5 } else { $_.DeltaPercent -le -5 } }).Count -gt 0
    $decision = if ($severeRegression -or $score -lt -1) { 'ROLLBACK' } elseif ($score -ge $BenchmarkMargin -and -not $qualityIssues.Count) { 'KEEP' } else { 'RETEST' }
    $confidence = [math]::Min(99,[math]::Round(55+[math]::Min(20,$before.Frames/500)+[math]::Min(15,$after.Frames/500)+$(if(-not $qualityIssues.Count){10}else{0}),0))
    [pscustomobject]@{ Timestamp=(Get-Date).ToString('o'); Decision=$decision; Score=[math]::Round($score,2); Margin=$BenchmarkMargin; Baseline=$before; Post=$after; Metrics=$metrics; FrameCountDeltaPercent=$frameDeltaPercent; QualityIssues=@($qualityIssues); Confidence=$confidence; SevereRegression=$severeRegression }
}
function Write-HtmlReport([object]$Decision, [object]$Hardware, [object]$Bottleneck, [object]$Plan, [object]$RollbackStatus) {
    $path = Join-Path $Data ('reports\naveboost_turbo_{0}.html' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    $esc = { param($v) [System.Net.WebUtility]::HtmlEncode([string]$v) }
    $safeClass = & $esc $Bottleneck.Class
    $safeConfidence = & $esc $Bottleneck.Confidence
    $safeProfile = & $esc $Plan.Profile
    $safeSafety = & $esc $Plan.Safety
    $safeResult = & $esc $(if ($Decision) { $Decision.Decision } else { 'SCAN_ONLY' })
    $safeChanges = & $esc (($Plan.Changes) -join '; ')
    $safeHardware = & $esc ($Hardware | ConvertTo-Json -Depth 5)
    $safeRollback = & $esc ($RollbackStatus | ConvertTo-Json -Depth 5)
    $measurementLabel = if ($Decision -and $Decision.Metrics) {
        'resultado medido nesta sessão; não é uma estimativa'
    } else {
        'sem medição — resultado não verificado'
    }
    $metricRows = if ($Decision -and $Decision.Metrics) {
        ($Decision.Metrics | ForEach-Object {
            $name = & $esc $_.Name
            $before = & $esc $_.Before
            $after = & $esc $_.After
            $delta = & $esc $_.DeltaPercent
            "<tr><td>$name</td><td>$before</td><td>$after</td><td>$delta%</td></tr>"
        }) -join "`n"
    } else { '<tr><td colspan="4">sem medição — resultado não verificado</td></tr>' }
    $html = @"
<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><title>NaveBoost Turbo</title>
<style>body{font-family:Segoe UI,Arial;background:#10131a;color:#e8edf5;max-width:1000px;margin:32px auto;padding:0 20px}h1{color:#67e8f9}section{background:#191f2b;border:1px solid #2b3648;border-radius:12px;padding:18px;margin:14px 0}table{width:100%;border-collapse:collapse}td,th{padding:9px;border-bottom:1px solid #303b4d;text-align:left}.ok{color:#86efac}.warn{color:#fbbf24}</style></head>
<body><h1>NaveBoost Turbo</h1>
<section><h2>Decisão</h2><p><strong>Gargalo:</strong> $safeClass ($safeConfidence% confiança)</p><p><strong>Perfil:</strong> $safeProfile / $safeSafety</p><p><strong>Resultado:</strong> $safeResult</p><p><strong>Alterações:</strong> $safeChanges</p></section>
<section><h2>Hardware</h2><pre>$safeHardware</pre></section>
 <section><h2>Benchmark</h2><p>$measurementLabel</p><table><tr><th>Métrica</th><th>Antes</th><th>Depois</th><th>Variação</th></tr>$metricRows</table></section>
<section><h2>Rollback</h2><pre>$safeRollback</pre></section>
</body></html>
"@
    $html | Set-Content -LiteralPath $path -Encoding UTF8
    Write-Log "relatório HTML criado: $path"
    return $path
}

function Select-AutoProfile([object]$Hardware, [object]$Telemetry) {
    if ($Telemetry.ThermalHint -eq 'processo ausente') { return 'safe' }
    $lowEnd = ($Hardware.RamGb -le 8) -or ($Hardware.LogicalProcessors -le 4) -or (($Hardware.VramGb -as [double]) -and $Hardware.VramGb -le 4)
    if ($lowEnd -or $Telemetry.ThermalHint -match 'thermal') { return 'low-end' }
    if ($Telemetry.GpuPercent -and $Telemetry.GpuPercent -ge 85) { return 'quality' }
    return 'competitive'
}

function Start-Turbo {
    Test-Prerequisites
    $scan = Invoke-AdaptiveScan
    if (-not $scan.Ready) { return }
    $name = $scan.Game
    $hardware = $scan.Hardware
    $telemetry = $scan.Telemetry
    $bottleneck = $scan.Bottleneck
    $plan = $scan.Plan
    $selected = $plan.Profile
    $script:Profile = $selected
    $script:TurboApplyPriority = $plan.ApplyPriority
    if ($script:TurboApplyPriority) {
        $script:Priority = 'abovenormal'
        $Priority = 'abovenormal'
    }
    $decision = [pscustomobject]@{
        Timestamp = (Get-Date).ToString('o')
        Game = $name
        Hardware = $hardware
        InitialTelemetry = $telemetry
        Bottleneck = $bottleneck
        SafePlan = $plan
        SelectedProfile = $selected
        HistoricalBestProfile = $scan.HistoricalBestProfile
        ExperimentalApplied = $false
        Reason = $bottleneck.Reason
    }
    $decisionPath = Join-Path $Data ('reports\turbo_decision_{0}.json' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    $decision | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $decisionPath -Encoding UTF8
    Write-Host ("Turbo: SCAN -> {0} -> {1} -> {2}" -f $scan.Stage, $bottleneck.Class, $selected)
    Write-Host ("Motivo: {0}" -f $bottleneck.Reason)
    if (-not $plan.ApplyPriority -or [double]$bottleneck.Confidence -lt 80) {
        Write-Host "Nenhum tweak SAFE foi aplicado: confiança $($bottleneck.Confidence)% ou ausência de mudança segura não atingiu o mínimo de 80%."
        Write-HtmlReport $null $hardware $bottleneck $plan ([pscustomobject]@{ Status='not_applied'; Reason='no evidence of benefit' })
        return
    }
    Start-Session
    if (-not (Test-Path -LiteralPath $SessionFile)) { return }
    if ($Experimental -and [double]$bottleneck.Confidence -ge 80 -and $plan.Safety -eq 'SAFE') {
        Invoke-AdaptiveSessionActions 'apply' $bottleneck.Class
        $sessionState = Get-Content -Raw -LiteralPath $SessionFile | ConvertFrom-Json
        $sessionState | Add-Member -NotePropertyName Bottleneck -NotePropertyValue $bottleneck.Class -Force
        $sessionState | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $SessionFile -Encoding UTF8
    }
    $samples = New-Object System.Collections.Generic.List[object]
    while (@(Get-GameProcesses $name).Count -gt 0) {
        Repair-TurboPriority $name
        try { $samples.Add((Get-SystemTelemetry $name)) } catch { Write-Log $_.Exception.Message 'WARN' }
        Start-Sleep -Seconds 4
    }
    Restore-Session
    $benchmark = $null
    if ($BaselineCsv -and $PostCsv) {
        $benchmark = Compare-Benchmarks $BaselineCsv $PostCsv
        Save-GameLearning $name $selected $benchmark $benchmark.Decision $hardware
        if ($benchmark.Decision -eq 'ROLLBACK') {
            Write-Log 'benchmark piorou o resultado; rollback já foi confirmado pela restauração de sessão' 'WARN'
        }
    }
    $finalPath = Join-Path $Data ('reports\turbo_session_{0}.json' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    $rollback = Get-ChildItem -LiteralPath (Join-Path $Data 'reports') -Filter 'rollback_verify_*.json' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $session = [pscustomobject]@{ Decision=$decision; Benchmark=$benchmark; Samples=@($samples); Restored=$true; RollbackVerification=if ($rollback) { $rollback.FullName } else { $null } }
    $session | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $finalPath -Encoding UTF8
    Write-HtmlReport $benchmark $hardware $bottleneck $plan $session
    Write-Host "Turbo finalizado. Relatorio: $finalPath"
}

if ($MyInvocation.InvocationName -eq '.') { return }

try {
    switch ($Action) {
        'start' { Start-Session }
        'turbo' { Start-Turbo }
        'stop' { Restore-Session }
        'rollback' { Restore-Session }
        'discover' { Get-GameLibraries }
        'telemetry' { Get-ThermalCorrelation }
        'bottleneck' { Get-BottleneckEstimate }
        'adaptive-scan' { Invoke-AdaptiveScan | Out-Null }
        'health' {
            $health = Get-HealthCheck
            Write-HealthReport $health | Out-Null
            if (-not $health.Ready) { exit 2 }
        }
        'benchmark' { Invoke-BenchmarkComparison | Out-Null }
        'report' { Invoke-Report | Out-Null }
        'verify' {
            $verifyScript = Join-Path $Root '00_core\verify_pack.ps1'
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $verifyScript
            if ($LASTEXITCODE -ne 0) { exit 4 }
        }
        'help' {
            Write-Output '[PROCESSO/APLICACAO] -GameExe aceita nome com ou sem .exe.'
            Write-Output '[PROCESSO/APLICACAO] caminho completo exige .exe e o arquivo precisa existir.'
            Write-Output 'Exemplos: -GameExe jogo | -GameExe jogo.exe | -GameExe "C:\Jogos\jogo.exe"'
        }
        'snapshot' {
            if (-not (Test-Administrator)) { throw 'snapshot requer executar como administrador' }
            $snapScript = Join-Path $Root '10_backup_rollback\09_snapshot_all.bat'
            Write-Log "executando snapshot: $snapScript"
            if ($DryRun) { $rc = 0 } else {
                & cmd.exe /d /c ('call "{0}"' -f $snapScript) 2>&1 | ForEach-Object { Write-Log ([string]$_) }
                $rc = $LASTEXITCODE
            }
            if ($rc -ne 0) { throw "snapshot retornou codigo $rc" }
        }
        'diagnostic' {
            Write-Host 'NaveBoost: diagnóstico consolidado'
            Write-Host ("Windows: " + (Get-CimInstance Win32_OperatingSystem).Caption)
            Write-Host ("CPU: " + (Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Name))
            Get-CimInstance Win32_VideoController | Select-Object Name,DriverVersion | Format-Table -AutoSize
            Get-CimInstance Win32_ComputerSystem | Select-Object TotalPhysicalMemory,NumberOfLogicalProcessors | Format-List
            & powercfg.exe /getactivescheme
            Get-BottleneckEstimate
        }
    }
    exit 0
} catch {
    Write-Log $_.Exception.Message 'ERROR'
    if (-not (Test-Path -LiteralPath $SessionFile)) { Release-SessionLock }
    $message = $_.Exception.Message
    if ($message -match '(?i)admin|privileg') { exit 3 }
    if ($message -match '(?i)depend|não encontrado|nao encontrado|powershell') { exit 2 }
    if ($message -match '(?i)rollback|restaur') { exit 5 }
    exit 1
}
