@echo off

if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)
SET this_path=%~dp0
SET this_file=%~dpf0
echo "mode ADMIN"
echo this_path : %this_path%
echo this_file : %this_file%
%~d0
cd %this_path%
echo cd  : %cd%

echo --------------------------
SET SOFT_PATH=%this_path%mongodb\bin\
SET DIR_DB=%this_path%mongodb\bin\data\db\

mkdir %DIR_DB%
echo  '' >> %DIR_DB%log.txt

%SOFT_PATH%mongod.exe --remove
%SOFT_PATH%mongod.exe --dbpath=%DIR_DB% --logpath=%DIR_DB%log.txt --install
pause
net start MongoDB
pause
net stop MongoDB
pause
%SOFT_PATH%mongod.exe --remove
echo --------------------------
pause
