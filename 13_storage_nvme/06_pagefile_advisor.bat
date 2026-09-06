@echo off
call "%~dp0..\00_core\common.bat" >nul
powershell.exe -noprofile -command "$r=(get-ciminstance win32_computersystem).totalphysicalmemory/1gb; $p=get-ciminstance win32_pagefileusage -erroraction silentlycontinue; [pscustomobject]@{ram_gb=[math]::round($r,1);currentpagefilegb= if($p){[math]::round((($p|measure-object allocatedbasesize -sum).sum/1024),1)}else{0};recommendation='keep windows-managed pagefile unless diagnostics show a specific issue'} | format-list"
