@echo off
call "%~dp0..\00_core\common.bat" >nul
call "%~dp0..\00_core\require_admin.bat"
if errorlevel 5 exit /b 5
powershell.exe -noprofile -command "$a=get-netadapter -physical | where status -eq 'up' | select -first 1; if($a){get-netadapterpowermanagement -name $a.name | format-list}else{write-host 'nenhum adaptador fisico ativo.'}"
echo este script audita. alteracao permanente deve ser feita pelo usuario no driver.
