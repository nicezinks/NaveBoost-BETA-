param()

$sig = @'
[DllImport("ntdll.dll")]
public static extern int NtSetSystemInformation(int SystemInformationClass, IntPtr SystemInformation, int SystemInformationLength);

[DllImport("advapi32.dll", SetLastError=true)]
public static extern bool OpenProcessToken(IntPtr ProcessHandle, int DesiredAccess, out IntPtr TokenHandle);

[DllImport("advapi32.dll", SetLastError=true)]
public static extern bool LookupPrivilegeValue(string lpSystemName, string lpName, out long lpLuid);

[StructLayout(LayoutKind.Sequential)]
public struct TOKEN_PRIVILEGES
{
    public int PrivilegeCount;
    public long Luid;
    public int Attributes;
}

[DllImport("advapi32.dll", SetLastError=true)]
public static extern bool AdjustTokenPrivileges(IntPtr TokenHandle, bool DisableAllPrivileges, ref TOKEN_PRIVILEGES NewState, int BufferLength, IntPtr PreviousState, IntPtr ReturnLength);
'@

Add-Type -MemberDefinition $sig -Name NativeMem -Namespace NaveBoost -ErrorAction SilentlyContinue

try {
    $procHandle = [System.Diagnostics.Process]::GetCurrentProcess().Handle
    $tokenHandle = [IntPtr]::Zero

    [NaveBoost.NativeMem]::OpenProcessToken($procHandle, 40, [ref]$tokenHandle) | Out-Null

    $luid = 0
    [NaveBoost.NativeMem]::LookupPrivilegeValue($null, "SeProfileSingleProcessPrivilege", [ref]$luid) | Out-Null

    $tp = New-Object NaveBoost.NativeMem+TOKEN_PRIVILEGES
    $tp.PrivilegeCount = 1
    $tp.Luid = $luid
    $tp.Attributes = 2  # SE_PRIVILEGE_ENABLED

    [NaveBoost.NativeMem]::AdjustTokenPrivileges($tokenHandle, $false, [ref]$tp, 0, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null

    $cmdPtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(4)
    [System.Runtime.InteropServices.Marshal]::WriteInt32($cmdPtr, 4)
    $result = [NaveBoost.NativeMem]::NtSetSystemInformation(80, $cmdPtr, 4)
    [System.Runtime.InteropServices.Marshal]::FreeHGlobal($cmdPtr)

    if ($result -eq 0) {
        Write-Host "Standby list purgada com sucesso."
    } else {
        Write-Host "Standby list: retorno $result (pode exigir privilegio elevado ou nao ter nada pra purgar)."
    }
} catch {
    Write-Host "Falha ao purgar standby list: $($_.Exception.Message)"
}