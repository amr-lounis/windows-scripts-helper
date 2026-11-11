@echo off
mkdir "../archive" 2>nul
for /f "tokens=1* delims=|" %%a in ('git log --all --pretty^=format:"%%H|%%s"') do git archive --format zip --output "../archive/%%b_%%a.zip" %%a
pause