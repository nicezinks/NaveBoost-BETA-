[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$DataRoot = [IO.Path]::GetFullPath((Join-Path $Root 'data'))
$ReportDir = Join-Path $DataRoot 'reports'
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
$TxtPath = Join-Path $ReportDir 'full_static_audit.txt'
$JsonPath = Join-Path $ReportDir 'full_static_audit.json'
$Findings = New-Object System.Collections.Generic.List[object]

function Add-Finding([string]$Severity, [string]$Code, [string]$Path, [string]$Detail) {
    $Findings.Add([pscustomobject]@{
        Severity = $Severity
        Code = $Code
        Path = $Path
        Detail = $Detail
    })
}

function Relative([string]$Path) {
    return $Path.Substring($Root.Length + 1).Replace('\','/')
}

$versionPath = Join-Path $PSScriptRoot 'version.json'
if (-not (Test-Path -LiteralPath $versionPath)) {
    Add-Finding 'critical' 'version_missing' '00_core/version.json' 'versão central ausente'
    $version = $null
} else {
    try {
        $version = [string]((Get-Content -Raw -LiteralPath $versionPath | ConvertFrom-Json).version)
        if ([string]::IsNullOrWhiteSpace($version)) { throw 'campo version vazio' }
        Add-Finding 'ok' 'version_central' '00_core/version.json' $version
    } catch {
        Add-Finding 'critical' 'version_invalid' '00_core/version.json' $_.Exception.Message
        $version = $null
    }
}

$allFiles = @(Get-ChildItem -LiteralPath $Root -Recurse -File | Where-Object {
    $full = [IO.Path]::GetFullPath($_.FullName)
    -not $full.StartsWith($DataRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
})

foreach ($f in ($allFiles | Where-Object { $_.Extension -in '.bat','.cmd' })) {
    $text = Get-Content -Raw -LiteralPath $f.FullName
    foreach ($m in [regex]::Matches($text, '(?im)\b(?:call|start)\s+(?:"[^"]*"\s+)?(?:"([^"]+\.(?:bat|cmd|ps1|reg))"|([^\s"]+\.(?:bat|cmd|ps1|reg)))')) {
        $ref = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
        if (-not $ref -or $ref -match '^(?i)(?:https?://|[a-z]:\\|\\\\|%|!|%%|/)' ) { continue }
        $candidate = Join-Path $f.DirectoryName ($ref.Replace('/','\'))
        if (-not (Test-Path -LiteralPath $candidate)) {
            Add-Finding 'error' 'missing_reference' (Relative $f.FullName) $ref
        }
    }
}

$regFiles = @($allFiles | Where-Object { $_.Extension -ieq '.reg' })
foreach ($f in $regFiles) {
    $rel = Relative $f.FullName
    $lines = @(Get-Content -LiteralPath $f.FullName)
    $first = (($lines | Where-Object { $_.Trim() } | Select-Object -First 1).TrimStart([char]0xfeff))
    if ($first -cne 'Windows Registry Editor Version 5.00') {
        Add-Finding 'error' 'bad_reg_header' $rel 'use exatamente Windows Registry Editor Version 5.00'
    }
    $keyLines = @($lines | Where-Object { $_ -match '^\s*\[' })
    foreach ($key in $keyLines) {
        if ($key -notmatch '^\[HKEY_[A-Za-z0-9_\\ -]+\]$') {
            Add-Finding 'error' 'bad_reg_key' $rel $key.Trim()
        }
    }
}
if ($regFiles.Count -eq 33) {
    Add-Finding 'ok' 'reg_inventory' '' '33 arquivos .reg auditados'
} else {
    Add-Finding 'warning' 'reg_inventory' '' ("esperados 33 .reg; encontrados {0}" -f $regFiles.Count)
}

foreach ($f in ($allFiles | Where-Object { $_.Extension -in '.bat','.cmd','.ps1','.reg','.json' -and $_.Name -ne 'version.json' })) {
    $text = Get-Content -Raw -LiteralPath $f.FullName
    if ($text -match '(?i)(?<![\w.])7\.5(?:\.1)?(?:-adaptive)?(?![\w-])') {
        Add-Finding 'warning' 'hardcoded_version' (Relative $f.FullName) 'migre títulos e metadados para 00_core/version.json'
    }
}

$manifestPath = Join-Path $Root 'manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath)) {
    Add-Finding 'critical' 'manifest_missing' 'manifest.json' 'manifest ausente'
} elseif ($version) {
    try {
        $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
        if ([string]$manifest.version -ne $version) { Add-Finding 'error' 'manifest_version' 'manifest.json' "$($manifest.version) != $version" }
        $listed = @($manifest.files)
        if ([int]$manifest.file_count -ne $listed.Count) { Add-Finding 'error' 'manifest_count' 'manifest.json' 'file_count diferente da lista' }
        $actual = @($allFiles | Where-Object { $_.Name -notin @('manifest.json','validation_report.txt','pack_validation.txt') } |
            ForEach-Object { Relative $_.FullName })
        $map = @{}
        foreach ($entry in $listed) { $map[[string]$entry.path] = $entry }
        foreach ($path in $actual) {
            if (-not $map.ContainsKey($path)) { Add-Finding 'error' 'manifest_missing' $path 'arquivo não listado' }
        }
        foreach ($entry in $listed) {
            $file = Join-Path $Root ([string]$entry.path).Replace('/','\')
            if (-not (Test-Path -LiteralPath $file)) { Add-Finding 'error' 'manifest_path_missing' ([string]$entry.path) 'arquivo listado não existe'; continue }
            $item = Get-Item -LiteralPath $file
            $hash = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
            if ([int64]$entry.bytes -ne [int64]$item.Length) { Add-Finding 'error' 'manifest_bytes' ([string]$entry.path) 'bytes divergentes' }
            if ($hash -ne ([string]$entry.sha256).ToLowerInvariant()) { Add-Finding 'error' 'manifest_hash' ([string]$entry.path) 'SHA-256 divergente' }
        }
        Add-Finding 'ok' 'manifest_audited' 'manifest.json' ("{0} entradas verificadas" -f $listed.Count)
    } catch {
        Add-Finding 'critical' 'manifest_invalid' 'manifest.json' $_.Exception.Message
    }
}

$cliPath = Join-Path $Root '00_core\naveboost_cli.ps1'
if (Test-Path -LiteralPath $cliPath) {
    $cli = Get-Content -Raw -LiteralPath $cliPath
    foreach ($marker in @('Convert-BenchmarkRows','Get-StatisticMean','Repair-TurboPriority','Get-ProtectionDiagnostics','Get-MsiModeDiagnostics','Write-HtmlReport')) {
        if ($cli -notmatch [regex]::Escape($marker)) { Add-Finding 'error' 'required_marker_missing' '00_core/naveboost_cli.ps1' $marker }
    }
    if ($cli -match '\$medianMs\s*=') { Add-Finding 'ok' 'median_implemented' '00_core/naveboost_cli.ps1' 'mediana calculada a partir de sortedMs' }
    else { Add-Finding 'critical' 'median_missing' '00_core/naveboost_cli.ps1' 'mediana não implementada' }
}

foreach ($required in @('21_adaptive_engine\adaptive_session.ps1','21_adaptive_engine\optimization_catalog.json')) {
    if (Test-Path -LiteralPath (Join-Path $Root $required)) {
        Add-Finding 'ok' 'adaptive_module_present' ($required.Replace('\','/')) 'módulo adaptativo presente'
    } else {
        Add-Finding 'error' 'adaptive_module_missing' ($required.Replace('\','/')) 'módulo adaptativo ausente'
    }
}

$critical = @($Findings | Where-Object Severity -eq 'critical')
$errors = @($Findings | Where-Object Severity -eq 'error')
$warnings = @($Findings | Where-Object Severity -eq 'warning')
$status = if ($critical.Count) { 'critical' } elseif ($errors.Count) { 'error' } elseif ($warnings.Count) { 'warning' } else { 'ok' }
$summary = [pscustomobject]@{
    Product = 'NaveBoost Turbo Pro'
    Version = $version
    GeneratedAt = (Get-Date).ToString('o')
    Status = $status
    Counts = [pscustomobject]@{ Critical=$critical.Count; Error=$errors.Count; Warning=$warnings.Count; Info=0; Ok=@($Findings | Where-Object Severity -eq 'ok').Count }
    Findings = @($Findings)
}
$summary | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $JsonPath -Encoding UTF8
$lines = @(
    "NaveBoost Turbo Pro static audit"
    "version=$version"
    "generated=$($summary.GeneratedAt)"
    "status=$status"
    "critical=$($critical.Count) error=$($errors.Count) warning=$($warnings.Count) ok=$(@($Findings | Where-Object Severity -eq 'ok').Count)"
)
$lines += @($Findings | ForEach-Object { "{0}|{1}|{2}|{3}" -f $_.Severity,$_.Code,$_.Path,$_.Detail })
$lines | Set-Content -LiteralPath $TxtPath -Encoding UTF8
$lines | Write-Output

if ($critical.Count -or $errors.Count) { exit 1 }
exit 0
