@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
call "%~dp000_core\common.bat" >nul
title NaveBoost Turbo Pro %nb_version% - Central

set "action="
set "profile=safe"
set "game="
set "priority=abovenormal"
set "silent=0"
set "dryrun=0"
set "closebg=0"
set "logfile="
set "baseline="
set "post="
set "margin=1"
set "experimental=0"
set "hags=0"
set "json=0"

:parse
if "%~1"=="" goto parsed
if /i "%~1"=="--start" (set "action=start"&shift&goto parse)
if /i "%~1"=="--stop" (set "action=stop"&shift&goto parse)
if /i "%~1"=="--diagnostic" (set "action=diagnostic"&shift&goto parse)
if /i "%~1"=="--snapshot" (set "action=snapshot"&shift&goto parse)
if /i "%~1"=="--rollback" (set "action=rollback"&shift&goto parse)
if /i "%~1"=="--discover-games" (set "action=discover"&shift&goto parse)
if /i "%~1"=="--telemetry" (set "action=telemetry"&shift&goto parse)
if /i "%~1"=="--bottleneck" (set "action=bottleneck"&shift&goto parse)
if /i "%~1"=="--adaptive-scan" (set "action=adaptive-scan"&shift&goto parse)
if /i "%~1"=="--health" (set "action=health"&shift&goto parse)
if /i "%~1"=="--benchmark" (set "action=benchmark"&shift&goto parse)
if /i "%~1"=="--report" (set "action=report"&shift&goto parse)
if /i "%~1"=="--verify" (set "action=verify"&shift&goto parse)
if /i "%~1"=="--turbo" (set "action=turbo"&shift&goto parse)
if /i "%~1"=="--profile" if not "%~2"=="" (set "profile=%~2"&shift&shift&goto parse)
if /i "%~1"=="--game" if not "%~2"=="" (set "game=%~2"&shift&shift&goto parse)
if /i "%~1"=="--priority" if not "%~2"=="" (set "priority=%~2"&shift&shift&goto parse)
if /i "%~1"=="--silent" (set "silent=1"&shift&goto parse)
if /i "%~1"=="--dry-run" (set "dryrun=1"&shift&goto parse)
if /i "%~1"=="--close-background" (set "closebg=1"&shift&goto parse)
if /i "%~1"=="--log" if not "%~2"=="" (set "logfile=%~2"&shift&shift&goto parse)
if /i "%~1"=="--baseline" if not "%~2"=="" (set "baseline=%~2"&shift&shift&goto parse)
if /i "%~1"=="--post" if not "%~2"=="" (set "post=%~2"&shift&shift&goto parse)
if /i "%~1"=="--margin" if not "%~2"=="" (set "margin=%~2"&shift&shift&goto parse)
if /i "%~1"=="--experimental" (set "experimental=1"&shift&goto parse)
if /i "%~1"=="--hags" if not "%~2"=="" (set "hags=%~2"&shift&shift&goto parse)
if /i "%~1"=="--json" (set "json=1"&shift&goto parse)
if /i "%~1"=="--help" (goto help)
echo argumento desconhecido: %~1
endlocal & exit /b 2

:parsed
if defined action goto run_action

:menu
cls
echo ================================================================
echo                 NAVEBOOST TURBO PRO %nb_version%
echo ================================================================
echo [1] Diagnostico consolidado
echo [2] Descobrir jogos instalados
echo [3] Criar snapshot de seguranca
echo [4] Iniciar sessao segura
echo [5] Iniciar sessao competitiva
echo [6] Encerrar sessao e restaurar
echo [7] Analisar gargalo CPU/GPU
echo [8] Monitorar temperatura e clock
echo [9] Benchmark com PresentMon
echo [10] Rollback da ultima sessao
echo [11] Verificar pacote
echo [12] NaveBoost Turbo automatico
echo [13] Health check
echo [14] Scan adaptativo sem tweaks
echo [15] Gerar relatorio HTML
echo [0] Sair
echo ================================================================
echo [PROCESSO/APLICACAO] informe o nome com ou sem .exe. Para caminho completo, use o arquivo .exe.
set "choice="
set /p "choice=Escolha: "
if "%choice%"=="1" (set "action=diagnostic"&goto run_action)
if "%choice%"=="2" (set "action=discover"&goto run_action)
if "%choice%"=="3" (set "action=snapshot"&goto run_action)
if "%choice%"=="4" (set "action=start"&set "profile=safe"&goto ask_game)
if "%choice%"=="5" (set "action=start"&set "profile=competitive"&goto ask_game)
if "%choice%"=="6" (set "action=stop"&goto run_action)
if "%choice%"=="7" (set "action=bottleneck"&goto run_action)
if "%choice%"=="8" (set "action=telemetry"&goto run_action)
if "%choice%"=="9" (call "%~dp019_benchmark_automation\01_baseline_capture.bat"&pause&goto menu)
if "%choice%"=="10" (set "action=rollback"&goto run_action)
if "%choice%"=="11" (call "%~dp000_core\verify_pack.bat"&pause&goto menu)
if "%choice%"=="12" (set "action=turbo"&goto ask_game)
if "%choice%"=="13" (set "action=health"&goto run_action)
if "%choice%"=="14" (set "action=adaptive-scan"&goto ask_game)
if "%choice%"=="15" (set "action=report"&goto run_action)
if "%choice%"=="0" (endlocal & exit /b 0)
echo Opcao invalida.
timeout /t 1 >nul
goto menu

:ask_game
if defined game goto run_action
set /p "game=[PROCESSO/APLICACAO] nome com ou sem .exe; caminho completo com .exe: "
goto run_action

:help
echo.
echo NaveBoost Turbo Pro %nb_version% - uso:
echo   start_here.bat --diagnostic [--silent]
echo   start_here.bat --adaptive-scan --game "jogo.exe"
echo   start_here.bat --turbo --game "C:\Jogos\jogo.exe"
echo   start_here.bat --benchmark --baseline "antes.csv" --post "depois.csv"
echo.
echo [PROCESSO/APLICACAO] --game aceita "jogo", "jogo.exe" ou um caminho completo.
echo [PROCESSO/APLICACAO] se for caminho de arquivo, o .exe e obrigatorio e o caminho deve existir.
echo.
endlocal & exit /b 0

:run_action
set "psargs=-Action %action% -Profile %profile% -Priority %priority%"
if defined game set "psargs=%psargs% -GameExe "%game%""
if "%silent%"=="1" set "psargs=%psargs% -Silent"
if "%dryrun%"=="1" set "psargs=%psargs% -DryRun"
if "%closebg%"=="1" set "psargs=%psargs% -CloseBackground"
if defined logfile set "psargs=%psargs% -LogPath "%logfile%""
if defined baseline set "psargs=%psargs% -BaselineCsv "%baseline%""
if defined post set "psargs=%psargs% -PostCsv "%post%""
if defined margin set "psargs=%psargs% -BenchmarkMargin %margin%"
if "%experimental%"=="1" set "psargs=%psargs% -Experimental"
if not "%hags%"=="0" set "psargs=%psargs% -HagsMode %hags%"
if "%json%"=="1" set "psargs=%psargs% -JsonOutput"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp000_core\naveboost_cli.ps1" %psargs%
set "rc=%errorlevel%"
if defined action if not "%action%"=="start" if not "%action%"=="stop" if not "%action%"=="rollback" pause
if defined action if "%action%"=="start" if "%silent%"=="0" pause
if "%silent%"=="1" (endlocal & exit /b %rc%)
set "action="
set "game="
goto menu