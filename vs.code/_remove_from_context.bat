@echo off
setlocal enabledelayedexpansion

set "soft=vscode"

:: Check for administrative privileges
net session >nul 2>&1 || (echo Please run as administrator && pause && exit /b 1)

echo Starting deletion process...
echo --------------------------

:: Delete file context menu entries
reg delete "HKEY_CLASSES_ROOT\*\shell\Open with !soft!\command" /f >nul 2>&1 && echo Successfully deleted file command || echo File command not found
reg delete "HKEY_CLASSES_ROOT\*\shell\Open with !soft!" /f >nul 2>&1 && echo Successfully deleted file context menu || echo File context menu not found

:: Delete directory context menu entries
reg delete "HKEY_CLASSES_ROOT\Directory\shell\!soft!\command" /f >nul 2>&1 && echo Successfully deleted directory command || echo Directory command not found
reg delete "HKEY_CLASSES_ROOT\Directory\shell\!soft!" /f >nul 2>&1 && echo Successfully deleted directory context menu || echo Directory context menu not found

:: Delete background context menu entries
reg delete "HKEY_CLASSES_ROOT\Directory\Background\shell\!soft!\command" /f >nul 2>&1 && echo Successfully deleted background command || echo Background command not found
reg delete "HKEY_CLASSES_ROOT\Directory\Background\shell\!soft!" /f >nul 2>&1 && echo Successfully deleted background context menu || echo Background context menu not found

echo --------------------------
echo Deletion process completed!
echo You may need to reboot to see changes
pause