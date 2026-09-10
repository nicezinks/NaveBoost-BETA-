@echo off
call "%~dp0..\00_core\common.bat" >nul
powershell.exe -noprofile -command "$c=get-ciminstance win32_processor; $r=(get-ciminstance win32_computersystem).totalphysicalmemory/1gb; $g=@(get-ciminstance win32_videocontroller); $ramclass=if($r -lt 8){'entrada'}elseif($r -lt 16){'media'}else{'alta'}; [pscustomobject]@{ramgb=[math]::round($r,1);physicalcores=($c|measure-object numberofcores -sum).sum;gpus=($g.name -join '; ');ramclass=$ramclass} | format-list"
