@echo off
setlocal

:: Admin check
net session >nul 2>&1 || (
    PowerShell -Command "Start-Process -Verb RunAs -FilePath '%~f0'" && exit
)
cd /d "%~dp0"

set "DataDir=data"
set "ServiceName=mysqlService"
set "Port=3306"

:menu
cls
echo ================================
echo  MySQL Manager
echo  DataDir: %DataDir%
echo  Service: %ServiceName%  Port: %Port%
echo ================================
echo  1. Make Data Directory (init)
echo  2. Delete Data Directory
echo  3. Create Service
echo  4. Delete Service
echo  5. Start Server
echo  6. Stop Server
echo  7. Restart Server
echo  8. Create Database
echo  9. Create User
echo  10. List Databases
echo  11. List Users
echo  0. Exit
echo.
set /p "opt=Select [0-11]: "
if "%opt%"=="0" exit /b
if "%opt%"=="1" goto make
if "%opt%"=="2" goto deldata
if "%opt%"=="3" goto create
if "%opt%"=="4" goto delete
if "%opt%"=="5" goto start
if "%opt%"=="6" goto stop
if "%opt%"=="7" goto restart
if "%opt%"=="8" goto createdb
if "%opt%"=="9" goto createuser
if "%opt%"=="10" goto listdb
if "%opt%"=="11" goto listuser
goto menu

:make
cls
echo [Make Data Directory]
if exist "%DataDir%" (
    echo Deleting old data...
    bin\mysqladmin -u root shutdown >nul 2>&1
    timeout /t 2 /nobreak >nul
    rmdir /s /q "%DataDir%"
)

echo Creating my.ini...
(
echo [mysqld]
echo basedir=%CD%
echo datadir=%CD%\%DataDir%
echo port=%Port%
echo bind-address=127.0.0.1
) > my.ini

echo Initializing data directory (insecure - root no password)...
bin\mysqld --defaults-file="%CD%\my.ini" --initialize-insecure

echo Starting MySQL temporarily...
start /b bin\mysqld --defaults-file="%CD%\my.ini" --console >nul 2>&1
echo Waiting 5 seconds...
timeout /t 5 /nobreak >nul

echo Creating default user and database...
bin\mysql -u root -e "CREATE USER 'user1'@'localhost' IDENTIFIED BY 'password1'; CREATE DATABASE db1; GRANT ALL PRIVILEGES ON db1.* TO 'user1'@'localhost'; FLUSH PRIVILEGES;"

bin\mysqladmin -u root shutdown

echo.
echo ================================
echo  MySQL Created Successfully!
echo ================================
echo  Path      : %CD%\%DataDir%
echo.
echo  Default Databases:
echo    - mysql (system)
echo    - sys (system)
echo    - db1
echo.
echo  Default Users:
echo    - root (no password) - superuser
echo    - user1 / password1 (owner of db1)
echo.
echo  Connection:
echo    Host: localhost
echo    Port: %Port%
echo    Database: db1
echo    User: user1
echo    Password: password1
echo    Root: mysql -u root
echo ================================
pause
goto menu

:deldata
cls
echo [Delete Data Directory]
if not exist "%DataDir%" (
    echo Data directory not found.
    pause
    goto menu
)
choice /M "Delete data directory '%DataDir%' ?"
if %errorlevel%==2 goto menu
bin\mysqladmin -u root shutdown >nul 2>&1
timeout /t 2 /nobreak >nul
rmdir /s /q "%DataDir%"
echo [Done] Data deleted.
pause
goto menu

:create
cls
echo [Create Service]
if not exist "%DataDir%" (
    echo Data not found, make it first.
    pause
    goto menu
)
bin\mysqld --install %ServiceName% --defaults-file="%CD%\my.ini"
sc config "%ServiceName%" start= auto >nul
net start "%ServiceName%"
echo [Done] Service %ServiceName% created.
pause
goto menu

:delete
cls
echo [Delete Service]
net stop "%ServiceName%" >nul 2>&1
bin\mysqld --remove %ServiceName% >nul 2>&1
sc delete "%ServiceName%" >nul 2>&1
echo [Done] Service deleted.
pause
goto menu

:start
cls
echo [Start]
net start "%ServiceName%" >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Service not installed, starting standalone...
    start /b bin\mysqld --defaults-file="%CD%\my.ini" --console
)
echo [Done] Started.
pause
goto menu

:stop
cls
echo [Stop]
bin\mysqladmin -u root shutdown >nul 2>&1
net stop "%ServiceName%" >nul 2>&1
echo [Done] Stopped.
pause
goto menu

:restart
cls
echo [Restart]
bin\mysqladmin -u root shutdown >nul 2>&1
net stop "%ServiceName%" >nul 2>&1
timeout /t 2 /nobreak >nul
net start "%ServiceName%" >nul 2>&1
if %errorlevel% NEQ 0 (
    start /b bin\mysqld --defaults-file="%CD%\my.ini" --console
)
echo [Done] Restarted.
pause
goto menu

:createdb
cls
echo [Create Database]
set "DbName="
set /p "DbName=Enter database name: "
if "%DbName%"=="" goto menu
bin\mysql -u root -e "CREATE DATABASE %DbName%;"
echo [Done] Database %DbName% created.
pause
goto menu

:createuser
cls
echo [Create User]
set "NewUser="
set "NewPass="
set /p "NewUser=Enter username: "
if "%NewUser%"=="" goto menu
set /p "NewPass=Enter password: "
if "%NewPass%"=="" set "NewPass=password"
bin\mysql -u root -e "CREATE USER '%NewUser%'@'localhost' IDENTIFIED BY '%NewPass%';"
set "TargetDb="
set /p "TargetDb=Grant to database (empty=skip): "
if not "%TargetDb%"=="" (
    bin\mysql -u root -e "GRANT ALL PRIVILEGES ON %TargetDb%.* TO '%NewUser%'@'localhost'; FLUSH PRIVILEGES;"
)
echo [Done] User %NewUser% created.
pause
goto menu

:listdb
cls
echo [List Databases]
bin\mysql -u root -e "SHOW DATABASES;"
pause
goto menu

:listuser
cls
echo [List Users]
bin\mysql -u root -e "SELECT user, host FROM mysql.user;"
pause
goto menu
