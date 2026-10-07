@echo off

if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
SET this_path=%~dp0
SET this_file=%~dpf0
echo "mode ADMIN"
echo --------------------------------------------
set /p d_win=Enter the letter of the Windows disk: 
set /p d_name=Enter the name windows:
echo --------------------------------------------
echo disk Windows : %d_win%
echo --------------------------------------------

bcdboot %d_win%:\Windows
bcdedit /set {default} bootmenupolicy legacy
bcdedit /set {default} description "%d_name%"
echo --------------------------------------------
pause