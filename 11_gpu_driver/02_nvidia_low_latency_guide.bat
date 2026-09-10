@echo off
call "%~dp0..\00_core\common.bat" >nul
where nvcplui.exe >nul 2>&1 && start "nvidia control panel" nvcplui.exe || echo nvidia control panel nao encontrado no path.
echo checklist manual: low latency mode conforme o jogo, power management conforme perfil, v-sync conforme vrr/cap.
echo este script nao injeta dll nem modifica arquivos do jogo.
pause
