[CmdletBinding()]
param([string]$OutputZip)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$versionInfo = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'version.json') | ConvertFrom-Json
if (-not $OutputZip) { $OutputZip = Join-Path (Split-Path $Root -Parent) ("NaveBoost-{0}.zip" -f $versionInfo.version) }
$Updater = Join-Path $Root '00_core\update_manifest.ps1'
$Verifier = Join-Path $Root '00_core\verify_pack.ps1'

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Updater
if ($LASTEXITCODE -ne 0) { throw 'falha ao atualizar manifest' }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Verifier
if ($LASTEXITCODE -ne 0) { throw 'validação falhou; ZIP não criado' }

if (Test-Path -LiteralPath $OutputZip) { Remove-Item -LiteralPath $OutputZip -Force }
Compress-Archive -Path (Join-Path $Root '*') -DestinationPath $OutputZip -CompressionLevel Optimal -Force
$checksumPath = "$OutputZip.sha256"
$hash = (Get-FileHash -LiteralPath $OutputZip -Algorithm SHA256).Hash.ToLowerInvariant()
("{0}  {1}" -f $hash, [IO.Path]::GetFileName($OutputZip)) | Set-Content -LiteralPath $checksumPath -Encoding ASCII
Write-Host "release criado: $OutputZip"
Write-Host "sha256 criado: $checksumPath"
