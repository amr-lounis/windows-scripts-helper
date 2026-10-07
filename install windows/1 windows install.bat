@echo off

if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
SET this_path=%~dp0
SET this_file=%~dpf0
echo "mode ADMIN"
echo --------------------------------------------
echo type 1 : wim
echo type 2 : esd
echo --------------------------------------------
set /p type_number=Enter the type of boot: 
IF %type_number%==1 (
SET type=wim
)
IF NOT %type_number%==1 (
SET type=esd    
)
echo --------------------------------------------
set /p d_source=Enter the letter of the Windows disk SOURCE: 
echo --------------------------------------------
set /p d_destination=Enter the letter of the Windows disk DESTINATION: 
echo --------------------------------------------
dism /get-wiminfo /wimfile:%d_source%:\sources\install.%type%
set /p d_index=Enter the index of Windows: 
echo --------------------------------------------
echo Type : %type%
echo source : %d_source%
echo destination : %d_destination%
echo index : %d_index%
echo --------------------------------------------
pause

dism  /apply-image /imagefile:%d_source%:\sources\install.%type% /index:%d_index% /applydir:%d_destination%:\

echo --------------------------------------------
pause
