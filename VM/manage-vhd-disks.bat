@echo off
setlocal enabledelayedexpansion
title VHD / VHDX Disk Manager

rem ---- Run as administrator ----
if not "%1"=="am_admin" (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -ArgumentList 'am_admin' -Verb RunAs"
    exit /b
)

:menu
cls
echo ==========================================
echo        VHD / VHDX Disk Manager
echo ==========================================
echo.
echo   1 - Create a new VHD/VHDX
echo   2 - Attach an existing VHD/VHDX
echo   3 - Detach a VHD/VHDX
echo   4 - Attach and format a new/blank VHD/VHDX
echo   5 - List attached VHD/VHDX
echo   0 - Exit
echo.
set "CHOICE="
set /p "CHOICE=Your choice: "
if defined CHOICE set "CHOICE=%CHOICE: =%"
echo.

if "%CHOICE%"=="1" goto create
if "%CHOICE%"=="2" goto attach
if "%CHOICE%"=="3" goto detach
if "%CHOICE%"=="4" goto format
if "%CHOICE%"=="5" goto list
if "%CHOICE%"=="0" exit /b
goto menu

rem ============================================================
rem  Create a new virtual disk
rem ============================================================
:create
echo [i] Leave the path empty to use the default location.
set "VHD="
set /p "VHD=Path (.vhd or .vhdx): "
if defined VHD set "VHD=%VHD:"=%"
if not defined VHD set "VHD=%USERPROFILE%\Documents\VHDs\disk.vhd"

rem ---- Relative paths go to the default folder ----
if not "%VHD:~1,1%"==":" if not "%VHD:~0,2%"=="\\" set "VHD=%USERPROFILE%\Documents\VHDs\%VHD%"

for %%F in ("%VHD%") do (
    set "VHD=%%~fF"
    set "VHD_EXT=%%~xF"
    set "VHD_DIR=%%~dpF"
)

if /i not "!VHD_EXT!"==".vhd" if /i not "!VHD_EXT!"==".vhdx" (
    echo [ERROR] The file name must end with .vhd or .vhdx
    pause
    goto menu
)
if exist "!VHD!" (
    echo [ERROR] File already exists: "!VHD!"
    pause
    goto menu
)
if not exist "!VHD_DIR!" mkdir "!VHD_DIR!" >nul 2>&1
if not exist "!VHD_DIR!" (
    echo [ERROR] Could not create the folder: "!VHD_DIR!"
    pause
    goto menu
)

:create_size
set "SIZE_GB="
set /p "SIZE_GB=Size in GB (VHD max 2040, VHDX max 65536): "
if not defined SIZE_GB goto create_size
set "SIZE_GB=%SIZE_GB: =%"
if not defined SIZE_GB goto create_size
echo !SIZE_GB!| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo [ERROR] Enter a whole number.
    goto create_size
)
set /a SIZE_MB=!SIZE_GB!*1024
if !SIZE_MB! LSS 8 (
    echo [ERROR] Minimum size is 8 MB.
    goto create_size
)
if /i "!VHD_EXT!"==".vhd" if !SIZE_GB! GTR 2040 (
    echo [ERROR] VHD files are limited to 2040 GB. Use .vhdx instead.
    goto create_size
)
if /i "!VHD_EXT!"==".vhdx" if !SIZE_GB! GTR 65536 (
    echo [ERROR] VHDX files are limited to 65536 GB.
    goto create_size
)

:create_type
set "VTYPE=expandable"
set "TT="
set /p "TT=Type: E = expandable, F = fixed [default E]: "
if defined TT set "TT=%TT: =%"
if /i "!TT!"=="F" set "VTYPE=fixed"
if defined TT if /i not "!TT!"=="F" if /i not "!TT!"=="E" (
    echo [ERROR] Enter E or F.
    goto create_type
)

set "DPFILE=%TEMP%\vhd_create_%RANDOM%.txt"
> "%DPFILE%" echo create vdisk file="!VHD!" maximum=!SIZE_MB! type=!VTYPE!
>>"%DPFILE%" echo exit
echo.
echo Creating !VTYPE! !VHD_EXT! disk of !SIZE_GB! GB...
echo.
diskpart /s "%DPFILE%"
set "RC=!ERRORLEVEL!"
del "%DPFILE%" >nul 2>&1

if not exist "!VHD!" (
    echo.
    echo [ERROR] The virtual disk was not created.
    pause
    goto menu
)
echo.
echo [OK] Created: "!VHD!"

set "AF="
set /p "AF=Attach and format it now? [Y/N]: "
if defined AF set "AF=!AF: =!"
if /i "!AF!"=="Y" (
    set "LABEL=VHD"
    set /p "LABEL=Volume label [default VHD]: "
    set "LABEL=!LABEL:~0,32!"
    call :format_disk "!VHD!" "!LABEL!"
)
pause
goto menu

rem ============================================================
rem  Attach an existing virtual disk
rem ============================================================
:attach
call :ask_existing
call :attach_disk "!VHD!"
if not "!RC!"=="0" (
    echo.
    echo [ERROR] Attach failed. Check the path and whether it is already attached.
) else (
    echo.
    echo [OK] Attached: "!VHD!"
)
pause
goto menu

rem ============================================================
rem  Detach a virtual disk
rem ============================================================
:detach
call :ask_existing
call :detach_disk "!VHD!"
if not "!RC!"=="0" (
    echo.
    echo [ERROR] Detach failed. Close any files or programs using the disk.
) else (
    echo.
    echo [OK] Detached: "!VHD!"
)
pause
goto menu

rem ============================================================
rem  Attach and format a virtual disk
rem ============================================================
:format
echo WARNING: Use this only on a new or blank virtual disk.
echo Any data on the disk may be erased.
echo.
call :ask_existing
set "OK="
set /p "OK=Continue? [Y/N]: "
if defined OK set "OK=!OK: =!"
if /i not "!OK!"=="Y" goto menu
set "LABEL=VHD"
set /p "LABEL=Volume label [default VHD]: "
set "LABEL=!LABEL:~0,32!"
call :format_disk "!VHD!" "!LABEL!"
pause
goto menu

rem ============================================================
rem  List attached virtual disks
rem ============================================================
:list
set "DPFILE=%TEMP%\vhd_list_%RANDOM%.txt"
> "%DPFILE%" echo list vdisk
>>"%DPFILE%" echo exit
echo Attached virtual disks:
echo.
diskpart /s "%DPFILE%"
del "%DPFILE%" >nul 2>&1
echo.
pause
goto menu

goto :eof

rem ============================================================
rem  Functions
rem ============================================================
:ask_existing
set "VHD="
set /p "VHD=Full path of the VHD/VHDX file: "
if defined VHD set "VHD=%VHD:"=%"
if not defined VHD goto ask_existing
if not exist "%VHD%" (
    echo [ERROR] File not found: "%VHD%"
    goto ask_existing
)
for %%F in ("%VHD%") do set "VHD=%%~fF"
exit /b

:attach_disk
set "DPFILE=%TEMP%\vhd_attach_%RANDOM%.txt"
> "%DPFILE%" echo select vdisk file="%~1"
>>"%DPFILE%" echo attach vdisk
>>"%DPFILE%" echo exit
diskpart /s "%DPFILE%"
set "RC=%ERRORLEVEL%"
del "%DPFILE%" >nul 2>&1
exit /b %RC%

:detach_disk
set "DPFILE=%TEMP%\vhd_detach_%RANDOM%.txt"
> "%DPFILE%" echo select vdisk file="%~1"
>>"%DPFILE%" echo detach vdisk
>>"%DPFILE%" echo exit
diskpart /s "%DPFILE%"
set "RC=%ERRORLEVEL%"
del "%DPFILE%" >nul 2>&1
exit /b %RC%

:format_disk
rem %1 = virtual disk path, %2 = volume label
set "DPFILE=%TEMP%\vhd_format_%RANDOM%.txt"
> "%DPFILE%" echo select vdisk file="%~1"
>>"%DPFILE%" echo attach vdisk
>>"%DPFILE%" echo create partition primary
>>"%DPFILE%" echo format quick fs=ntfs label="%~2"
>>"%DPFILE%" echo assign
>>"%DPFILE%" echo exit
echo.
echo Attaching and formatting as NTFS (label: %~2)...
echo.
diskpart /s "%DPFILE%"
set "RC=%ERRORLEVEL%"
del "%DPFILE%" >nul 2>&1
if not "%RC%"=="0" (
    echo [ERROR] Formatting failed. The disk may already be initialized or in use.
) else (
    echo [OK] Disk attached, formatted and assigned a drive letter.
)
exit /b %RC%
