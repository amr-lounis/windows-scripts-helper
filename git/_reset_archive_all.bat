@echo off
setlocal

:: Current folder name
for %%I in (.) do set "FOLDER_NAME=%%~nxI"

set "ARCHIVE_DIR=../%FOLDER_NAME%_archive"
mkdir "%ARCHIVE_DIR%" 2>nul

for /f "tokens=1* delims=|" %%a in ('git log --all --pretty^=format:"%%H|%%s"') do git archive --format zip --output "%ARCHIVE_DIR%/%%b_%%a.zip" %%a

pause
