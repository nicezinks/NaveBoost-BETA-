param(
    [string]$StateDir
)

$memBeforePath   = Join-Path $StateDir "mem_before.state"
$availBeforePath = Join-Path $StateDir "avail_before.state"
$procBeforePath  = Join-Path $StateDir "proc_before.state"
$killedCountPath = Join-Path $StateDir "killed_count.state"
$reportPath      = Join-Path $StateDir "last_run_report.txt"

$memBefore   = [int64](Get-Content $memBeforePath)
$availBefore = [double](Get-Content $availBeforePath)
$procBefore  = [int](Get-Content $procBeforePath)
$killedCount = 0
if (Test-Path $killedCountPath) { $killedCount = [int](Get-Content $killedCountPath) }

Start-Sleep -Milliseconds 1500

$os = Get-CimInstance Win32_OperatingSystem
$memAfter  = $os.FreePhysicalMemory
$procAfter = (Get-Process).Count

try {
    $availAfter = (Get-Counter '\Memory\Available MBytes').CounterSamples[0].CookedValue
} catch {
    $availAfter = [math]::Round($memAfter / 1024, 0)
}

$freedFreeMB  = [math]::Round(($memAfter - $memBefore) / 1024, 0)
$freedAvailMB = [math]::Round($availAfter - $availBefore, 0)
$procKilledByCount = $procBefore - $procAfter

$lines = @(
    "NaveBoost ULTRA DEMONIACO - relatorio da execucao"
    "Data: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    ""
    "Memoria disponivel antes:  $([math]::Round($availBefore,0)) MB"
    "Memoria disponivel depois: $([math]::Round($availAfter,0)) MB"
    "Memoria liberada (Available, igual ao Gerenciador de Tarefas): ~$freedAvailMB MB"
    "Memoria liberada (Free Physical, mais conservador):            ~$freedFreeMB MB"
    ""
    "Processos antes:  $procBefore"
    "Processos depois: $procAfter"
    "Processos encerrados pelo script: $killedCount"
    "Diferenca liquida de processos (pode ser menor que o acima, pois alguns servicos/apps reiniciam sozinhos): $procKilledByCount"
    ""
    "Lista completa dos processos mortos: state\killed_processes.txt"
    "Top 40 sobreviventes por RAM (pra caçar o que ainda sobra): state\survivors_top40.txt"
)

$lines | Set-Content -Encoding ASCII $reportPath
$lines | ForEach-Object { Write-Host $_ }