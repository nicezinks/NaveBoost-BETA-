@echo off
call "%~dp0..\00_core\common.bat" >nul
reg query "hklm\software\policies\microsoft\windows\psched" /v nonbesteffortlimit
