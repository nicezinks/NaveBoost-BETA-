@echo off
setlocal enableextensions
cd /d "%~dp0"
call "%~dp0..\00_core\common.bat" >nul
set /p "pn=executavel do jogo (sem .exe): "
set /p "sec=duracao em segundos (padrao 60): "
if not defined sec set "sec=60"
for /f "delims=0123456789" %%a in ("%sec%") do set "badsec=1"
if defined badsec echo duracao invalida.& exit /b 2
if "%sec%"=="0" echo duracao deve ser maior que zero.& exit /b 2
if not defined pn echo executavel obrigatorio.& exit /b 2
set "csv=%nb_bench%\baseline_%random%.csv"
set "pm="
if exist "%~dp0..\09_tools\bin\presentmon.exe" set "pm=%~dp0..\09_tools\bin\presentmon.exe"
if not defined pm for /f "delims=" %%p in ('where presentmon.exe 2^>nul') do if not defined pm set "pm=%%p"
if not defined pm echo presentmon.exe nao encontrado. coloque em 09_tools\bin ou no path.& exit /b 3
"%pm%" --stop_existing_session --terminate_after_timed --timed %sec% --process_name "%pn%.exe" --output_file "%csv%" --no_console_stats
set "rc=%errorlevel%"
if not "%rc%"=="0" (echo presentmon terminou com codigo %rc%.& exit /b %rc%)
if not exist "%csv%" (echo csv nao foi criado.& exit /b 4)
echo %csv%>"%nb_bench%\baseline_latest.txt"
echo captura concluida: %csv%
exit /b 0
