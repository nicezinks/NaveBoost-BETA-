param(
    [string]$StateDir
)

$patterns = @(
    'SysMain','WSearch','DiagTrack','DoSvc','BITS','MapsBroker','lfsvc',
    'TabletInputService','Fax','Spooler','WerSvc','PcaSvc','RetailDemo',
    'WalletService','PhoneSvc','WMPNetworkSvc','wisvc','CscService','SEMgrSvc',
    'SharedAccess','wuauserv','UsoSvc','WaaSMedicSvc','WbioSrvc','SSDPSRV',
    'upnphost','StorSvc','DusmSvc','BthAvctpSvc','bthserv','Themes','DPS',
    'RemoteRegistry',
    'CDPSvc','CDPUserSvc*','FrameServer*','PimIndexMaintenanceSvc*',
    'UnistoreSvc*','UserDataSvc*','OneSyncSvc*','WpnUserService*','shpamsvc'
)

$services = foreach ($p in $patterns) {
    Get-CimInstance Win32_Service -Filter "Name LIKE '$($p.Replace('*','%'))'" -ErrorAction SilentlyContinue
}
$services = $services | Sort-Object Name -Unique

$services | ForEach-Object { '{0}|{1}' -f $_.Name, $_.StartMode } |
    Set-Content -Encoding ASCII (Join-Path $StateDir "services.state")

$stopped = 0
foreach ($svc in $services) {
    try {

        Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name $svc.Name -Force -ErrorAction Stop
        $stopped++
    } catch {
        try { & sc.exe config $svc.Name start= disabled | Out-Null } catch {}
        try { & sc.exe stop $svc.Name | Out-Null } catch {}
    }
}

Write-Host "Servicos parados/desabilitados: $stopped de $($services.Count) encontrados"