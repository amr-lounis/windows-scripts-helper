@echo off
setlocal enabledelayedexpansion
title PATH Editor - Machine
chcp 65001 >nul 2>&1

:: NOTE: entries containing ! are not supported due to delayed expansion.
set "REG_KEY=HKLM\System\CurrentControlSet\Control\Session Manager\Environment"

:: Admin check + auto-elevate - Machine PATH requires admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:menu
cls
echo ==================================================
echo  PATH EDITOR - Machine
echo ==================================================
echo.
echo  [1] Show entries
echo  [2] Add new entries (multi-line)
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

:: Load Machine PATH from registry, preserves value type
:load_path
set "RAW_PATH="
set "PATH_TYPE=REG_EXPAND_SZ"
for /f "tokens=2*" %%A in ('reg query "%REG_KEY%" /v Path 2^>nul') do (
    set "PATH_TYPE=%%A"
    set "RAW_PATH=%%B"
)
exit /b 0

:: Split RAW_PATH on ; into E1..En, sets N. Paren-safe: no data inside for-set.
:split_raw
set "N=0"
set "REST=!RAW_PATH!"
set "REST=!REST:"=!"
if not defined REST exit /b 0
:split_next
if not defined REST exit /b 0
if "!REST:~0,1!"==";" set "REST=!REST:~1!" & goto :split_next
set "SEG="
for /f "tokens=1* delims=;" %%a in ("!REST!") do (
    set "SEG=%%a"
    set "REST=%%b"
)
if not defined SEG exit /b 0
set /a N+=1
set "E!N!=!SEG!"
goto :split_next

:: Print numbered entries from E1..N. Plain echo is safe for & and parens.
:print_entries
for /l %%i in (1,1,!N!) do echo  %%i. !E%%i!
exit /b 0

:: Write NEW_PATH back: backup + empty-guard + reg add /f + read-back verify
:save_path
if not defined NEW_PATH (
    if defined RAW_PATH (
        echo [ERROR] Refusing to write empty PATH. Nothing was changed.
        exit /b 1
    )
)
set "STAMP=%DATE:/=-%_%TIME::=-%"
set "STAMP=!STAMP: =0!"
set "STAMP=!STAMP:.=!"
set "BAK_FILE=%TEMP%\PathBackup_!STAMP!.reg"
reg export "%REG_KEY%" "!BAK_FILE!" /y >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Backup failed - aborting. Nothing was changed.
    exit /b 1
)
echo [BACKUP] Saved to: !BAK_FILE!
reg add "%REG_KEY%" /v Path /t !PATH_TYPE! /d "!NEW_PATH!" /f >nul
if errorlevel 1 (
    echo [ERROR] Failed to write registry. Backup at: !BAK_FILE!
    exit /b 1
)
set "CHECK_PATH="
for /f "tokens=2*" %%A in ('reg query "%REG_KEY%" /v Path 2^>nul') do set "CHECK_PATH=%%B"
if "!CHECK_PATH!"=="!NEW_PATH!" (
    echo [SUCCESS] Machine PATH updated and verified.
) else (
    echo [ERROR] Verification failed. Backup at: !BAK_FILE!
    exit /b 1
)
:: Notify running programs - setx always broadcasts the change, dummy var removed after
setx PATH_EDITOR_SYNC "1" >nul 2>&1
reg delete HKCU\Environment /v PATH_EDITOR_SYNC /f >nul 2>&1
echo Note: reopen terminal windows to see the change.
exit /b 0

:: ================= SHOW =================
:show
cls
echo ==================================================
echo  MACHINE PATH ENTRIES
echo ==================================================
echo.
call :load_path
call :split_raw
call :print_entries
if !N!==0 echo  No entries found.
echo.
echo --------------------------------------------------
echo  Total entries: !N!
echo --------------------------------------------------
pause
goto :menu

:: ================= ADD (multi-line) =================
:add
cls
echo ==================================================
echo  ADD NEW PATH ENTRIES
echo ==================================================
echo.
echo  Paste or type one directory per line.
echo  An EMPTY line ends the input and saves.
echo  (Pasting a block that ends with an empty line works.)
echo.
call :load_path
call :split_raw
set "NEW_PATH=!RAW_PATH!"
set "ADDED=0"
set "SKIPPED=0"

:add_loop
set "NEW_ENTRY="
set /p "NEW_ENTRY="
if "!NEW_ENTRY!"=="" goto :add_done
set "NEW_ENTRY=!NEW_ENTRY:"=!"
:trim_add
if "!NEW_ENTRY!"=="" goto :add_done
if "!NEW_ENTRY:~0,1!"==" " set "NEW_ENTRY=!NEW_ENTRY:~1!" & goto :trim_add
if "!NEW_ENTRY:~-1!"==" " set "NEW_ENTRY=!NEW_ENTRY:~0,-1!" & goto :trim_add
if "!NEW_ENTRY:~-1!"==";" set "NEW_ENTRY=!NEW_ENTRY:~0,-1!" & goto :trim_add
if "!NEW_ENTRY!"=="" goto :add_done
if "!NEW_ENTRY:~-1!"=="\" (
    if not "!NEW_ENTRY:~-2,1!"==":" set "NEW_ENTRY=!NEW_ENTRY:~0,-1!"
)

:: Missing directory: skip (no Y/N prompt, it would swallow pasted lines)
if not exist "!NEW_ENTRY!\" (
    echo  [SKIP] Directory does not exist: !NEW_ENTRY!
    set /a SKIPPED+=1
    goto :add_loop
)

:: Duplicate check against existing entries AND entries added in this session
set "DUP=0"
for /l %%i in (1,1,!N!) do if /i "!E%%i!"=="!NEW_ENTRY!" set "DUP=1"
if "!DUP!"=="1" (
    echo  [SKIP] Already exists: !NEW_ENTRY!
    set /a SKIPPED+=1
    goto :add_loop
)

if defined NEW_PATH (
    set "NEW_PATH=!NEW_PATH!;!NEW_ENTRY!"
) else (
    set "NEW_PATH=!NEW_ENTRY!"
)
set /a N+=1
set "E!N!=!NEW_ENTRY!"
set /a ADDED+=1
echo  [ADD]  !NEW_ENTRY!
goto :add_loop

:add_done
echo.
echo --------------------------------------------------
echo  To add: !ADDED!   Skipped: !SKIPPED!
echo --------------------------------------------------
if "!ADDED!"=="0" (
    echo Nothing to save.
    pause
    goto :menu
)
call :save_path
pause
goto :menu

:: ================= DELETE =================
:delete
cls
echo ==================================================
echo  DELETE PATH ENTRY
echo ==================================================
echo.
call :load_path
call :split_raw
call :print_entries
if !N!==0 (
    echo No entries to delete.
    pause
    goto :menu
)
echo.
echo --------------------------------------------------
echo Type number to delete, path to delete by name,
echo or leave empty to cancel.
echo --------------------------------------------------
set "DEL_INPUT="
set /p "DEL_INPUT=Delete target: "
if "!DEL_INPUT!"=="" goto :menu
set "DEL_INPUT=!DEL_INPUT:"=!"

:: Numeric check via digit-strip - safe for & | and $ anchor issues
set "NUMTEST=X!DEL_INPUT!"
for %%d in (0 1 2 3 4 5 6 7 8 9) do set "NUMTEST=!NUMTEST:%%d=!"
if "!NUMTEST!"=="X" (
    call :delete_by_number "!DEL_INPUT!"
) else (
    call :delete_by_name "!DEL_INPUT!"
)
pause
goto :menu

:delete_by_number
set "TARGET_NUM=%~1"
for /f "tokens=* delims=0" %%z in ("0!TARGET_NUM!") do set "TARGET_NUM=%%z"
if not defined TARGET_NUM set "TARGET_NUM=0"
if !TARGET_NUM! lss 1 (
    echo [ERROR] Invalid number.
    exit /b 1
)
if !TARGET_NUM! gtr !N! (
    echo [ERROR] Invalid number.
    exit /b 1
)
set "LINE_TO_DEL=!E%TARGET_NUM%!"
echo.
echo Will delete: !LINE_TO_DEL!
set "CONFIRM="
set /p "CONFIRM=Confirm? [Y/N]: "
if /i not "!CONFIRM!"=="Y" (
    echo Cancelled.
    exit /b 0
)
set "NEW_PATH="
for /l %%i in (1,1,!N!) do (
    if %%i neq !TARGET_NUM! (
        if defined NEW_PATH (
            set "NEW_PATH=!NEW_PATH!;!E%%i!"
        ) else (
            set "NEW_PATH=!E%%i!"
        )
    )
)
call :save_path
exit /b 0

:delete_by_name
set "NEEDLE=%~1"
:trim_needle
if "!NEEDLE:~0,1!"==" " set "NEEDLE=!NEEDLE:~1!" & goto :trim_needle
if "!NEEDLE:~-1!"==" " set "NEEDLE=!NEEDLE:~0,-1!" & goto :trim_needle
if "!NEEDLE:~-1!"==";" set "NEEDLE=!NEEDLE:~0,-1!" & goto :trim_needle
if "!NEEDLE!"=="" (
    echo [ERROR] Empty target.
    exit /b 1
)
if "!NEEDLE:~-1!"=="\" (
    if not "!NEEDLE:~-2,1!"==":" set "NEEDLE=!NEEDLE:~0,-1!"
)
set "FOUND=0"
for /l %%i in (1,1,!N!) do (
    set "TSEG=!E%%i!"
    if "!TSEG:~-1!"=="\" set "TSEG=!TSEG:~0,-1!"
    if /i "!TSEG!"=="!NEEDLE!" (
        set /a FOUND+=1
        echo  match: !TSEG!
    )
)
if "!FOUND!"=="0" (
    echo [ERROR] Not found.
    exit /b 1
)
echo.
set "CONFIRM="
set /p "CONFIRM=Delete ALL !FOUND! matching entries? [Y/N]: "
if /i not "!CONFIRM!"=="Y" (
    echo Cancelled.
    exit /b 0
)
set "NEW_PATH="
for /l %%i in (1,1,!N!) do (
    set "TSEG=!E%%i!"
    set "TSEG2=!TSEG!"
    if "!TSEG2:~-1!"=="\" set "TSEG2=!TSEG2:~0,-1!"
    if /i not "!TSEG2!"=="!NEEDLE!" (
        if defined NEW_PATH (
            set "NEW_PATH=!NEW_PATH!;!TSEG!"
        ) else (
            set "NEW_PATH=!TSEG!"
        )
    )
)
call :save_path
exit /b 0
