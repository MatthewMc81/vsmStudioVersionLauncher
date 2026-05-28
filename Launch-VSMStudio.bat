@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Launch-VSMStudio.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  Script exited with error code %ERRORLEVEL%
    pause
)
