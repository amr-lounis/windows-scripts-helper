@echo off
setlocal enabledelayedexpansion

:: Get the directory path of the current batch file
set "bat_dir=%~dp0"
set "exe_soft=Code.exe"
set "name_soft=vscode"

:: Check for administrator privileges
net session >nul 2>&1 || (echo This script must be run as an administrator && pause && exit /b 1)

:: Add registry keys for opening files with ...
reg add "HKEY_CLASSES_ROOT\*\shell\Open with !name_soft!" /ve /d "Edit with !name_soft!" /f || echo Failed to add registry entry
reg add "HKEY_CLASSES_ROOT\*\shell\Open with !name_soft!" /v "Icon" /d "\"!bat_dir!\!exe_soft!\",0" /f || echo Failed to add icon entry

reg add "HKEY_CLASSES_ROOT\*\shell\Open with !name_soft!\command" /ve /d "\"!bat_dir!!exe_soft!\" \"%%1\"" /f || echo Failed to add command entry

:: Add registry keys for opening folders with !name_soft!
reg add "HKEY_CLASSES_ROOT\Directory\shell\!name_soft!" /ve /d "Open Folder as !name_soft! Project" /f || echo Failed to add directory entry
reg add "HKEY_CLASSES_ROOT\Directory\shell\!name_soft!" /v "Icon" /d "\"!bat_dir!\!exe_soft!\",0" /f || echo Failed to add directory icon

reg add "HKEY_CLASSES_ROOT\Directory\shell\!name_soft!\command" /ve /d "\"!bat_dir!!exe_soft!\" \"%%1\"" /f || echo Failed to add directory command

:: Add registry keys for opening folders from the background context menu with !name_soft!
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\!name_soft!" /ve /d "Open Folder as !name_soft! Project" /f || echo Failed to add background entry
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\!name_soft!" /v "Icon" /d "\"!bat_dir!\!exe_soft!\",0" /f || echo Failed to add background icon

reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\!name_soft!\command" /ve /d "\"!bat_dir!!exe_soft!\" \"%%V\"" /f || echo Failed to add background command

:: Notify the user that the registry has been updated successfully
echo Registry updated successfully!
pause