@echo off
call "%~dp0..\00_core\common.bat" >nul
fsutil behavior query disabledeletenotify
