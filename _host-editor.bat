@echo off
setlocal enabledelayedexpansion
title Hosts Editor
chcp 65001 >nul 2>&1

set "HOSTS_FILE=%SystemRoot%\System32\drivers\etc\hosts"

:: Admin check + auto-elevate
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:menu
cls
echo ==================================================
echo  HOSTS EDITOR
echo  File: %HOSTS_FILE%
echo ==================================================
echo.
echo  [1] Show entries
echo  [2] Add new entry
echo  [3] Delete entry
echo.
echo  [0] Exit
echo.
set "CHOICE="
set /p "CHOICE=Choose option (0-3): "

if "%CHOICE%"=="1" goto :show
if "%CHOICE%"=="2" goto :add
if "%CHOICE%"=="3" goto :delete
if "%CHOICE%"=="0" exit /b 0

echo Invalid choice, try again.
timeout /t 2 >nul
goto :menu

:: ================= SHOW =================
:show
cls
echo ==================================================
echo  CURRENT HOSTS ENTRIES (active only)
echo ==================================================
echo.
set COUNT=0
for /f "tokens=*" %%A in ('findstr /v /r "^# ^$" "%HOSTS_FILE%" 2^>nul') do (
    set /a COUNT+=1
    echo  !COUNT!. %%A
)
if !COUNT!==0 echo  (no active entries found)
echo.
echo --------------------------------------------------
echo  Total active entries: !COUNT!
echo --------------------------------------------------
pause
goto :menu

:: ================= ADD =================
:add
cls
echo ==================================================
echo  ADD NEW HOST ENTRY
echo ==================================================
echo.
set "IP_INPUT="
set "HOST_INPUT="
set /p "IP_INPUT=Enter IP Address (e.g. 127.0.0.1) [empty=cancel]: "
if "!IP_INPUT!"=="" goto :menu
set /p "HOST_INPUT=Enter Hostname (e.g. mysite.local) [empty=cancel]: "
if "!HOST_INPUT!"=="" goto :menu

:: Remove spaces
set "IP_INPUT=!IP_INPUT: =!"
set "HOST_INPUT=!HOST_INPUT: =!"

:: Basic IP validation (NOTE: no space before | or findstr $ fails)
echo(!IP_INPUT!| findstr /r "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo.
    echo [ERROR] Invalid IP format: !IP_INPUT!
    echo Example of valid IP: 127.0.0.1
    pause
    goto :add
)

if "!HOST_INPUT!"=="" (
    echo [ERROR] Hostname cannot be empty.
    pause
    goto :add
)

:: Duplicate check
findstr /i /c:"!HOST_INPUT!" "%HOSTS_FILE%" >nul
if !errorlevel! equ 0 (
    echo.
    echo [SKIP] Hostname already exists: !HOST_INPUT!
    echo Use option [3] Delete first, or [1] Show to review.
    pause
    goto :menu
)

echo.
echo [ACTION] Adding: !IP_INPUT! !HOST_INPUT!
>> "%HOSTS_FILE%" echo !IP_INPUT!    !HOST_INPUT!
echo [SUCCESS] Entry added.
pause
goto :menu

:: ================= DELETE =================
:delete
cls
echo ==================================================
echo  DELETE HOST ENTRY
echo ==================================================
echo.
set COUNT=0
for /f "tokens=*" %%A in ('findstr /v /r "^# ^$" "%HOSTS_FILE%" 2^>nul') do (
    set /a COUNT+=1
    echo  !COUNT!. %%A
)
if !COUNT!==0 (
    echo No active entries to delete.
    pause
    goto :menu
)
echo.
echo --------------------------------------------------
echo Type number to delete, hostname/IP to delete by name,
echo or leave empty to cancel.
echo --------------------------------------------------
set "DEL_INPUT="
set /p "DEL_INPUT=Delete target: "
if "!DEL_INPUT!"=="" goto :menu

:: Check if input is a number (NOTE: no space before | or $ anchor fails)
echo(!DEL_INPUT!| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    call :delete_by_name "!DEL_INPUT!"
) else (
    call :delete_by_number "!DEL_INPUT!"
)
pause
goto :menu

:delete_by_number
set "TARGET_NUM=%~1"
set "IDX=0"
set "LINE_TO_DEL="
for /f "delims=" %%A in ('findstr /v /r "^# ^$" "%HOSTS_FILE%" 2^>nul') do (
    set /a IDX+=1
    if !IDX! equ %TARGET_NUM% (
        set "LINE_TO_DEL=%%A"
    )
)
if "!LINE_TO_DEL!"=="" (
    echo [ERROR] Invalid number: %TARGET_NUM%
    exit /b 1
)
echo.
echo Will delete: !LINE_TO_DEL!
set "CONFIRM="
set /p "CONFIRM=Confirm? (Y/N): "
if /i not "!CONFIRM!"=="Y" (
    echo Cancelled.
    exit /b 0
)
:: Delete exact line (first occurrence) - preserves empty lines via findstr /n
set "TEMP_FILE=%TEMP%\hosts_tmp_%RANDOM%.txt"
set "DELETED=0"
(for /f "tokens=1* delims=:" %%a in ('findstr /n "^" "%HOSTS_FILE%"') do (
    set "CURR=%%b"
    if "!DELETED!"=="0" (
        if "!CURR!"=="!LINE_TO_DEL!" (
            set "DELETED=1"
        ) else (
            echo(%%b
        )
    ) else (
        echo(%%b
    )
)) > "!TEMP_FILE!"
copy /y "!TEMP_FILE!" "%HOSTS_FILE%" >nul
del "!TEMP_FILE!" >nul 2>&1
echo [SUCCESS] Deleted entry #%TARGET_NUM%.
exit /b 0

:delete_by_name
set "TARGET_NAME=%~1"
findstr /i /c:"%TARGET_NAME%" "%HOSTS_FILE%" >nul
if errorlevel 1 (
    echo [ERROR] Not found: %TARGET_NAME%
    exit /b 1
)
echo.
echo Matching lines to delete:
echo --------------------------------------------------
findstr /i /c:"%TARGET_NAME%" "%HOSTS_FILE%"
echo --------------------------------------------------
set "CONFIRM="
set /p "CONFIRM=Delete ALL matching lines? (Y/N): "
if /i not "!CONFIRM!"=="Y" (
    echo Cancelled.
    exit /b 0
)
set "TEMP_FILE=%TEMP%\hosts_tmp_%RANDOM%.txt"
findstr /v /i /c:"%TARGET_NAME%" "%HOSTS_FILE%" > "!TEMP_FILE!"
copy /y "!TEMP_FILE!" "%HOSTS_FILE%" >nul
del "!TEMP_FILE!" >nul 2>&1
echo [SUCCESS] Deleted entries containing: %TARGET_NAME%
exit /b 0
