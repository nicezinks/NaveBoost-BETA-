param(
    [switch]$Apply,
    [switch]$Restore,
    [switch]$Scan
)

$ErrorActionPreference = 'SilentlyContinue'
$Base = Split-Path -Parent $MyInvocation.MyCommand.Path
$State = Join-Path $Base 'state'
New-Item -ItemType Directory -Path $State -Force | Out-Null
$Stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$Backup = Join-Path $State $Stamp
New-Item -ItemType Directory -Path $Backup -Force | Out-Null

$RemovePatterns = @(
    'Microsoft.3DViewer',
    'Microsoft.BingNews',
    'Microsoft.BingWeather',
    'Microsoft.GetHelp',
    'Microsoft.Getstarted',
    'Microsoft.Microsoft3DViewer',
    'Microsoft.MicrosoftJournal',
    'Microsoft.MicrosoftOfficeHub',
    'Microsoft.MicrosoftSolitaireCollection',
    'Microsoft.MixedReality.Portal',
    'Microsoft.People',
    'Microsoft.PowerAutomateDesktop',
    'Microsoft.SkypeApp',
    'Microsoft.Todos',
    'Microsoft.WindowsAlarms',
    'Microsoft.WindowsCommunicationsApps',
    'Microsoft.WindowsFeedbackHub',
    'Microsoft.WindowsMaps',
    'Microsoft.WindowsSoundRecorder',
    'Microsoft.XboxApp',
    'Microsoft.XboxGamingOverlay',
    'Microsoft.XboxIdentityProvider',
    'Microsoft.XboxSpeechToTextOverlay',
    'Microsoft.ZuneMusic',
    'Microsoft.ZuneVideo',
    'Clipchamp.Clipchamp'
)

$ProtectedPatterns = @(
    'Microsoft.WindowsStore',
    'Microsoft.StorePurchaseApp',
    'Microsoft.WindowsCalculator',
    'Microsoft.WindowsCamera',
    'Microsoft.WindowsNotepad',
    'Microsoft.WindowsTerminal',
    'Microsoft.Paint',
    'Microsoft.Windows.Photos',
    'Microsoft.ScreenSketch',
    'Microsoft.VCLibs',
    'Microsoft.NET',
    'Microsoft.UI.Xaml',
    'Microsoft.WindowsAppRuntime',
    'Microsoft.DesktopAppInstaller',
    'MicrosoftWindows.Client',
    'MicrosoftWindows.UndockedDevKit',
    'Microsoft.AAD.BrokerPlugin',
    'Microsoft.AccountsControl',
    'Microsoft.Windows.ShellExperienceHost',
    'Microsoft.Windows.StartMenuExperienceHost',
    'MicrosoftWindows.Client.CBS'
)

$TaskNames = @(
    '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser',
    '\Microsoft\Windows\Application Experience\ProgramDataUpdater',
    '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator',
    '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip',
    '\Microsoft\Windows\Feedback\Siuf\DmClient',
    '\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload'
)

function Is-ProtectedPackage([string]$Name) {
    foreach ($p in $ProtectedPatterns) {
        if ($Name -like "$p*") { return $true }
    }
    return $false
}

function Get-Targets {
    @(Get-AppxPackage -AllUsers | Where-Object {
        $n = $_.Name
        -not (Is-ProtectedPackage $n) -and (
            $RemovePatterns -contains $n -or
            $n -like 'Microsoft.Xbox*' -or
            $n -like 'Microsoft.YourPhone*'
        )
    } | Sort-Object Name -Unique)
}

if ($Scan) {
    $items = @(Get-Targets | Select-Object Name,Version,PackageFullName)
    $items | Format-Table -AutoSize
    $items | Out-File -Encoding utf8 (Join-Path $State 'scan.txt')
    Get-CimInstance Win32_StartupCommand |
        Where-Object { $_.Name -match 'OneDrive|Teams|Widgets|Skype|Xbox|Clipchamp' } |
        Select-Object Name,Command,Location |
        Format-Table -AutoSize
    exit 0
}

if ($Apply) {
    Get-Targets | ForEach-Object {
        $safe = ($_.PackageFullName -replace '[^A-Za-z0-9._-]','_')
        try {
            $_ | Select-Object Name,PackageFullName,Version |
                ConvertTo-Json -Depth 4 |
                Set-Content -Encoding utf8 (Join-Path $Backup "$safe.json")
            Remove-AppxPackage -Package $_.PackageFullName -AllUsers
        } catch {}
    }

    $oneDrive = Join-Path $env:SystemRoot 'SysWOW64\OneDriveSetup.exe'
    if (-not (Test-Path $oneDrive)) {
        $oneDrive = Join-Path $env:SystemRoot 'System32\OneDriveSetup.exe'
    }
    if (Test-Path $oneDrive) {
        try { Start-Process -FilePath $oneDrive -ArgumentList '/uninstall' -Wait -WindowStyle Hidden } catch {}
    }

    Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
        $path = "$($_.TaskPath)$($_.TaskName)"
        $TaskNames -contains $path
    } | ForEach-Object {
        try {
            $name = "$($_.TaskPath)$($_.TaskName)"
            Disable-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath | Out-Null
            Add-Content -Encoding utf8 -Path (Join-Path $Backup 'disabled_tasks.txt') -Value $name
        } catch {}
    }

    Get-AppxPackage -AllUsers | Where-Object {
        $_.Name -like 'Microsoft.Xbox*' -or $_.Name -like 'Microsoft.YourPhone*'
    } | Select-Object Name,PackageFullName |
        Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $Backup 'removed_packages.csv')

    Set-Content -Encoding utf8 (Join-Path $State 'last_backup.txt') $Backup
    Write-Host "debloat concluido: $Backup"
    exit 0
}

if ($Restore) {
    $last = Get-Content (Join-Path $State 'last_backup.txt') -ErrorAction SilentlyContinue
    if ($last -and (Test-Path $last)) {
        Get-ChildItem $last -Filter '*.json' | ForEach-Object {
            try {
                $data = Get-Content $_.FullName -Raw | ConvertFrom-Json
                if ($data.PackageFullName) {
                    Add-AppxPackage -Register "$env:SystemRoot\WinSxS\*\$($data.Name)*\AppxManifest.xml" -DisableDevelopmentMode -ErrorAction SilentlyContinue
                }
            } catch {}
        }
        $taskFile = Join-Path $last 'disabled_tasks.txt'
        if (Test-Path $taskFile) {
            Get-Content $taskFile | ForEach-Object {
                $line = $_
                $idx = $line.LastIndexOf('\')
                if ($idx -gt 0) {
                    $path = $line.Substring(0,$idx+1)
                    $name = $line.Substring($idx+1)
                    try { Enable-ScheduledTask -TaskPath $path -TaskName $name | Out-Null } catch {}
                }
            }
        }
    }
    exit 0
}
exit 2
