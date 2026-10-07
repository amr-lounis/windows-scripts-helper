@echo off

if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
SET this_path=%~dp0
SET this_file=%~dpf0
echo "mode ADMIN"
echo --------------------------------------------
echo type 1 : EFI
echo type 2 : BIOS
echo --------------------------------------------
set /p type_number=Enter the type of boot: 
IF %type_number%==1 (
SET type=UEFI

SET v_fs=fat32
)
IF NOT %type_number%==1 (
SET type=BIOS

SET v_fs=ntfs
)
echo --------------------------------------------
set /p d_win=Enter the letter of the Windows disk: 
set /p d_name=Enter the name windows:
echo --------------------------------------------
set /p d_boot=Enter the letter of the Boot disk: 
echo you need to format partition %d_boot%: by %v_fs% .
echo --------------------------------------------
echo disk fs : %v_fs%
echo disk Type : %type%
echo disk Windows : %d_win%
echo disk Boot : %d_boot%
echo --------------------------------------------
pause
echo --------------------------------------------

bcdboot %d_win%:\Windows /s %d_boot%: /F %type%  
bcdedit /set {default} bootmenupolicy legacy
bcdedit /set {default} description "%d_name%"
echo --------------------------------------------
pause