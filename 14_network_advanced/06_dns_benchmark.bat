@echo off
call "%~dp0..\00_core\common.bat" >nul
powershell.exe -noprofile -command "$servers='1.1.1.1','8.8.8.8','9.9.9.9'; foreach($s in $servers){$t=measure-command {resolve-dnsname example.com -server $s -erroraction silentlycontinue|out-null}; [pscustomobject]@{dns=$s;ms=[math]::round($t.totalmilliseconds,1)}} | format-table -autosize"
