param(
    [string]$StateDir
)

$os = Get-CimInstance Win32_OperatingSystem
$os.FreePhysicalMemory | Set-Content -Encoding ASCII (Join-Path $StateDir "mem_before.state")
(Get-Process).Count | Set-Content -Encoding ASCII (Join-Path $StateDir "proc_before.state")

try {
    $avail = (Get-Counter '\Memory\Available MBytes').CounterSamples[0].CookedValue
} catch {
    $avail = [math]::Round($os.FreePhysicalMemory / 1024, 0)
}
$avail | Set-Content -Encoding ASCII (Join-Path $StateDir "avail_before.state")