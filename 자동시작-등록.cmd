@echo off
rem Run Windows PowerShell by full path so this works even when PATH is broken.
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PS%" set "PS=powershell.exe"
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-Autostart.ps1"
pause
