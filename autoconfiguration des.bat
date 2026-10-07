@echo off
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
SET this_path=%~dp0
SET this_file=%~dpf0
echo "mode ADMIN"


netsh interface ipv4 show inter
set /p index=Enter the index for desable: 

netsh interface ipv4 set interface %index% dadtransmits=0 store=persistent

pause