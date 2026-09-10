[CmdletBinding()]
param([switch]$Check)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ManifestPath = Join-Path $Root 'manifest.json'
$VersionPath = Join-Path $PSScriptRoot 'version.json'
$VersionInfo = Get-Content -Raw -LiteralPath $VersionPath | ConvertFrom-Json
$Version = [string]$VersionInfo.version
if ([string]::IsNullOrWhiteSpace($Version)) { throw '00_core/version.json sem uma versão válida' }
$excludedNames = @('manifest.json','validation_report.txt','pack_validation.txt')
$dataRoot = [IO.Path]::GetFullPath((Join-Path $Root 'data'))

$files = @(Get-ChildItem -LiteralPath $Root -Recurse -File | Where-Object {
    $full = [IO.Path]::GetFullPath($_.FullName)
    ($excludedNames -notcontains $_.Name) -and (-not $full.StartsWith($dataRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase))
} | Sort-Object FullName)

$entries = foreach ($f in $files) {
    $relative = $f.FullName.Substring($Root.Length + 1).Replace('\','/')
    $hash = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    [pscustomobject]@{ path=$relative; bytes=[int64]$f.Length; sha256=$hash }
}

$expected = [pscustomobject]@{
    version = $Version
    file_count = $entries.Count
    files = @($entries)
}

if ($Check) {
    if (-not (Test-Path -LiteralPath $ManifestPath)) { throw 'manifest.json ausente' }
    $actual = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
    if ([string]$actual.version -ne $expected.version) { throw "manifest version mismatch: $($actual.version) != $($expected.version)" }
    if ([int]$actual.file_count -ne $expected.file_count) { throw "manifest file_count mismatch: $($actual.file_count) != $($expected.file_count)" }
    $map = @{}
    foreach ($e in @($actual.files)) { $map[[string]$e.path] = $e }
    foreach ($e in $entries) {
        if (-not $map.ContainsKey($e.path)) { throw "manifest missing: $($e.path)" }
        $a = $map[$e.path]
        if ([int64]$a.bytes -ne [int64]$e.bytes) { throw "manifest bytes mismatch: $($e.path)" }
        if ([string]$a.sha256 -ine [string]$e.sha256) { throw "manifest hash mismatch: $($e.path)" }
    }
    if ($map.Count -ne $entries.Count) { throw 'manifest possui arquivos extras' }
    Write-Host "manifest OK: $($entries.Count) arquivos"
    exit 0
}

$expected | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ManifestPath -Encoding UTF8
Write-Host "manifest atualizado: $($entries.Count) arquivos"
