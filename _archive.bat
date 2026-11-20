@echo off
setlocal enabledelayedexpansion

:: Current folder name
for %%I in (.) do set "FOLDER_NAME=%%~nxI"

set "ARCHIVE_DIR=../_archive/%FOLDER_NAME%_archive"
mkdir "%ARCHIVE_DIR%" 2>nul

:: Find last version
:: Archive names may include a commit hash, for example vrni_v1_a5e8f0c.zip.
:: Parse only the number after _v so "1_hash" cannot beat "10".
set MAX=0
for %%F in ("%ARCHIVE_DIR%\%FOLDER_NAME%_v*.zip") do (
    if exist "%%~fF" (
        set "NAME=%%~nF"
        set "NUM=!NAME:%FOLDER_NAME%_v=!"
        for /f "tokens=1 delims=_" %%N in ("!NUM!") do set "NUM=%%N"
        set /a NUM=NUM+0
        if !NUM! gtr !MAX! set MAX=!NUM!
    )
)
set /a NEXT=MAX+1
set "VERSION=%FOLDER_NAME%_v%NEXT%"

:: Commit
set /p COMMIT_VALUE=Enter commit message [%VERSION%]: 
if "%COMMIT_VALUE%"=="" set "COMMIT_VALUE=%VERSION%"

git add .
git commit -m "%COMMIT_VALUE%"
git archive --format zip --output "%ARCHIVE_DIR%\%VERSION%.zip" HEAD

echo.
echo Created: %ARCHIVE_DIR%\%VERSION%.zip
echo.
echo --- Content of %ARCHIVE_DIR% ---
dir /b /o-n "%ARCHIVE_DIR%"

pause
