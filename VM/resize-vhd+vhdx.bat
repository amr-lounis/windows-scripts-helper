@echo off
chcp 65001 >nul
echo ===================================================
echo    VHD / VHDX Resize Tool via Diskpart
echo ===================================================
echo.

set /p "vhd_path=Enter file path (e.g. F:\backup\win11.vhd): "
set /p "new_size=Enter new size in MB (e.g. 92160): "

echo.
echo Executing commands, please wait...

(
echo select vdisk file="%vhd_path%"
echo expand vdisk maximum=%new_size%
echo exit
) > "%temp%\diskpart_expand.txt"

diskpart /s "%temp%\diskpart_expand.txt"

del "%temp%\diskpart_expand.txt"

echo.
echo ===================================================
echo Done!
echo ===================================================
pause