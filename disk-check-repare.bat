@echo off 
set /p drv=Enter drive letter to repair (e.g. D):
::slow
chkdsk %drv%: /f
::NTFS
::chkdsk %drv%: /scan /forceofflinefix 
pause