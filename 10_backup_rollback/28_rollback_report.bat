@echo off
setlocal enableextensions enabledelayedexpansion
title naveboost turbo pro 7.3
cd /d "%~dp0"

call "%~dp0..\00_core\common.bat" >nul
set "log=%nb_log%"

if exist ..\data\snapshots\labels.txt type ..\data\snapshots\labels.txt
if exist ..\data\snapshots\snapshot_hashes.csv type ..\data\snapshots\snapshot_hashes.csv
endlocal
