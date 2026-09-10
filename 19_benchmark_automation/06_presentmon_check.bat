@echo off
setlocal EnableExtensions
call "%~dp0..\00_core\common.bat" >nul
set "pm="
if exist "%~dp0..\09_tools\bin\PresentMon.exe" set "pm=%~dp0..\09_tools\bin\PresentMon.exe"
if not defined pm for /f "delims=" %%p in ('where PresentMon.exe 2^>nul') do if not defined pm set "pm=%%p"
if defined pm (
  echo PresentMon detectado: %pm%
  "%pm%" --help | findstr /i /c:"output_file" /c:"terminate_after_timed" /c:"process_name"
) else (
  echo PresentMon nao encontrado.
  echo Instale/adicione somente uma copia oficial em 09_tools\bin ou no PATH.
  exit /b 3
)
endlocal & exit /b 0