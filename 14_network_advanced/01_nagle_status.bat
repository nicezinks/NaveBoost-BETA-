@echo off
call "%~dp0..\00_core\common.bat" >nul
powershell.exe -noprofile -command "get-childitem 'hklm:\system\currentcontrolset\services\tcpip\parameters\interfaces' | foreach-object { $p=get-itemproperty $_.pspath -erroraction silentlycontinue; [pscustomobject]@{interface=$_.pschildname;tcpackfrequency=$p.tcpackfrequency;tcpnodelay=$p.tcpnodelay} } | format-table -autosize"
