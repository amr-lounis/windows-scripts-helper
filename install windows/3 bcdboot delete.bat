@echo off
setlocal enabledelayedexpansion
:: Check for administrator privileges
net session >nul 2>&1 || (echo This script must be run as an administrator && pause && exit /b 1)

echo "mode ADMIN"

:loop
echo ---------------------- list ----------------------
bcdedit /v

set /p identifier=Enter the identifier to delete: 

set "clean_id=%identifier:{=%"
set "clean_id=!clean_id:}=%!"

bcdedit /delete {!clean_id!}

cls
goto :loop
