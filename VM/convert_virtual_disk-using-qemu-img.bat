@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo        QEMU-IMG Disk Converter
echo ==========================================
echo.

rem ---- Supported formats (qemu name / output extension) ----
set "FMT1=raw"   & set "EXT1=img"
set "FMT2=qcow2" & set "EXT2=qcow2"
set "FMT3=vmdk"  & set "EXT3=vmdk"
set "FMT4=vdi"   & set "EXT4=vdi"
set "FMT5=vpc"   & set "EXT5=vhd"
set "FMT6=vhdx"  & set "EXT6=vhdx"
set "FMT7=qed"   & set "EXT7=qed"
set COUNT=7

rem ---- Use %1 if provided (drag and drop or command line), otherwise ask ----
set "SRC=%~1"
if defined SRC goto check_file

:ask_file
set "SRC="
set /p "SRC=Enter the full path of the disk file: "
set "SRC=%SRC:"=%"
if "%SRC%"=="" (
    echo [!] No path entered. Try again.
    goto ask_file
)

:check_file
if not exist "%SRC%" (
    echo [!] File not found: "%SRC%"
    goto ask_file
)

rem ---- Detect source format from extension ----
for %%F in ("%SRC%") do (
    set "EXTN=%%~xF"
    set "BASE=%%~dpnF"
)

set "SRCFMT="
if /i "%EXTN%"==".img"   set "SRCFMT=raw"
if /i "%EXTN%"==".raw"   set "SRCFMT=raw"
if /i "%EXTN%"==".bin"   set "SRCFMT=raw"
if /i "%EXTN%"==".qcow2" set "SRCFMT=qcow2"
if /i "%EXTN%"==".qcow"  set "SRCFMT=qcow2"
if /i "%EXTN%"==".vmdk"  set "SRCFMT=vmdk"
if /i "%EXTN%"==".vdi"   set "SRCFMT=vdi"
if /i "%EXTN%"==".vhd"   set "SRCFMT=vpc"
if /i "%EXTN%"==".vhdx"  set "SRCFMT=vhdx"
if /i "%EXTN%"==".qed"   set "SRCFMT=qed"

rem ---- Unknown extension: ask qemu-img to probe the file ----
if not defined SRCFMT (
    echo [i] Unknown extension "%EXTN%", probing file with qemu-img...
    for /f "tokens=3" %%A in ('qemu-img info "%SRC%" 2^>nul ^| findstr /b /c:"file format:"') do set "SRCFMT=%%A"
)
if not defined SRCFMT (
    echo [!] Could not detect the disk format.
    goto ask_file
)

echo.
echo Detected source format: %SRCFMT%
echo.
echo Convert to:
for /l %%J in (1,1,%COUNT%) do (
    set "F=!FMT%%J!"
    if not "!F!"=="!SRCFMT!" echo   %%J - !F!
)
echo   A - All of the above
echo.

:ask_fmt
set "CHOICE="
set /p "CHOICE=Your choice: "

if /i "%CHOICE%"=="A" (
    for /l %%J in (1,1,%COUNT%) do (
        set "F=!FMT%%J!"
        if not "!F!"=="!SRCFMT!" call :convert %%J
    )
    goto done
)

if not defined FMT%CHOICE% (
    echo [!] Invalid choice.
    goto ask_fmt
)
if "!FMT%CHOICE%!"=="%SRCFMT%" (
    echo [!] That is already the source format.
    goto ask_fmt
)
call :convert %CHOICE%
goto done

:convert
set "F=!FMT%1!"
set "E=!EXT%1!"
echo.
echo Converting to !F! ...
qemu-img convert -p -f %SRCFMT% -O !F! "%SRC%" "%BASE%.!E!"
if errorlevel 1 (
    echo [!] Conversion to !F! failed.
) else (
    echo [OK] Created: "%BASE%.!E!"
)
exit /b

:done
echo.
echo Done.
pause
endlocal
