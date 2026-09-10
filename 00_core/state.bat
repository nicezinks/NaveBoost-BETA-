@echo off
setlocal enableextensions
call "%~dp0common.bat"
set "rc=0"
if /i "%~1"=="write" (
  >"%nb_state%\session_state.ini" echo status=%~2
  >>"%nb_state%\session_state.ini" echo timestamp=%date% %time%
  goto :done
)
if /i "%~1"=="clear" del /q "%nb_state%\session_state.ini" >nul 2>&1
goto :done
:done
endlocal & exit /b %rc%
