@echo off
setlocal
start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0CodexConnectionFixer.ps1"
exit /b 0
