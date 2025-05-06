@echo off
echo Running purchase database commit script...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0commit-purchases.ps1" %*
pause 