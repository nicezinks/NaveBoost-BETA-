@echo off
call "%~dp0..\00_core\common.bat" >nul
reg query "hklm\software\microsoft\windows nt\currentversion\multimedia\systemprofile\tasks\games"
