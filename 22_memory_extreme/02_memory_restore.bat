@echo off
setlocal
net session >nul 2>&1
if not %errorlevel%==0 (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
set "BASE=%~dp0"
if exist "%BASE%state\services.state" powershell -NoProfile -ExecutionPolicy Bypass -Command "$rows=Get-Content '%BASE%state\services.state'; foreach($r in $rows){$a=$r -split '\|'; if($a.Count -eq 2){$name=$a[0];$mode=$a[1].ToLower(); if($mode -eq 'auto'){$start='auto'}elseif($mode -eq 'manual'){$start='demand'}elseif($mode -eq 'disabled'){$start='disabled'}else{$start='demand'}; sc.exe config $name start= $start | Out-Null; sc.exe start $name | Out-Null}}"
if exist "%BASE%05_svchost_restore.reg" reg import "%BASE%05_svchost_restore.reg" >nul 2>&1
powercfg /setactive SCHEME_BALANCED >nul 2>&1
start "" explorer.exe >nul 2>&1
echo Memory settings restored. Reinicie o Windows para o registro do svchost voltar ao padrao.
endlocal