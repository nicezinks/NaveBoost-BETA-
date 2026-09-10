[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$cli = Join-Path $root '00_core\naveboost_cli.ps1'
$fixture = Join-Path $PSScriptRoot 'fixtures\benchmark_sample.csv'
$localeFixture = Join-Path $PSScriptRoot 'fixtures\benchmark_locale.csv'

. $cli -Action diagnostic -MinBenchmarkFrames 3 -Silent
$result = Convert-BenchmarkRows $fixture

if ($result.Frames -ne 4) { throw "expected 4 frames, got $($result.Frames)" }
if ([math]::Abs($result.MedianFrameTimeMs - 17.5) -gt 0.001) { throw "median regression: $($result.MedianFrameTimeMs)" }
if ($result.AvgFps -le 0) { throw 'average FPS was not calculated' }
$locale = Convert-BenchmarkRows $localeFixture
if ([math]::Abs($locale.MedianFrameTimeMs - 25) -gt 0.001) { throw "localized CSV regression: $($locale.MedianFrameTimeMs)" }
Write-Output 'PASS Test-ConvertBenchmarkRows'
