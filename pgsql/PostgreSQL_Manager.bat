@echo off
setlocal

:: Admin check
net session >nul 2>&1 || (
    PowerShell -Command "Start-Process -Verb RunAs -FilePath '%~f0'" && exit
)
cd /d "%~dp0"

set "ClusterName=data"
set "ServiceName=pgsqlService"

:menu
cls
echo ================================
echo  PostgreSQL Manager
echo  Cluster: %ClusterName%
echo  Service: %ServiceName%
echo ================================
echo  1. Make Cluster
echo  2. Delete Cluster
echo  3. Create Service
echo  4. Delete Service
echo  5. Start Cluster
echo  6. Stop Cluster
echo  7. Restart Cluster
echo  8. Create Database
echo  9. Create User
echo  10. List Databases
echo  11. List Users
echo  0. Exit
echo.
set /p "opt=Select [0-11]: "
if "%opt%"=="0" exit /b
if "%opt%"=="1" goto make
if "%opt%"=="2" goto delcluster
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
echo [Make Cluster]
if exist "%ClusterName%" (
    echo Deleting old cluster...
    bin\pg_ctl -D "%ClusterName%" stop >nul 2>&1
    rmdir /s /q "%ClusterName%"
)
bin\initdb -D "%ClusterName%" -U postgres --encoding=UTF8
bin\pg_ctl -D "%ClusterName%" -w start
bin\psql -h localhost -U postgres -c "CREATE USER user1 WITH PASSWORD 'password1';"
bin\psql -h localhost -U postgres -c "CREATE DATABASE db1 OWNER user1;"
echo.
echo ================================
echo  Cluster Created Successfully!
echo ================================
echo  Path      : %CD%\%ClusterName%
echo.
echo  Default Databases:
echo    - postgres (system)
echo    - db1
echo.
echo  Default Users:
echo    - postgres (superuser, no password)
echo    - user1 / password1  (owner of db1)
echo.
echo  Connection:
echo    Host: localhost
echo    Port: 5432
echo    Database: db1
echo    User: user1
echo    Password: password1
echo ================================
echo.
echo Verifying...
bin\psql -h localhost -U postgres -c "\l"
bin\psql -h localhost -U postgres -c "\du"
bin\pg_ctl -D "%ClusterName%" stop
pause
goto menu

:delcluster
cls
echo [Delete Cluster]
if not exist "%ClusterName%" (
    echo Cluster not found.
    pause
    goto menu
)
choice /M "Delete cluster '%ClusterName%' ?"
if %errorlevel%==2 goto menu
bin\pg_ctl -D "%ClusterName%" stop >nul 2>&1
rmdir /s /q "%ClusterName%"
echo [Done] Cluster deleted.
pause
goto menu

:create
cls
if not exist "%ClusterName%" (
    echo Cluster not found.
    pause
    goto menu
)
bin\pg_ctl register -N "%ServiceName%" -D "%CD%\%ClusterName%"
sc config "%ServiceName%" start= auto >nul
net start "%ServiceName%"
echo [Done] Service created.
pause
goto menu

:delete
cls
net stop "%ServiceName%" >nul 2>&1
bin\pg_ctl unregister -N "%ServiceName%" >nul 2>&1
sc delete "%ServiceName%" >nul 2>&1
echo [Done] Service deleted.
pause
goto menu

:start
cls
bin\pg_ctl -D "%ClusterName%" start
pause
goto menu

:stop
cls
bin\pg_ctl -D "%ClusterName%" stop
pause
goto menu

:restart
cls
bin\pg_ctl -D "%ClusterName%" restart
if %errorlevel% NEQ 0 bin\pg_ctl -D "%ClusterName%" start
echo [Done] Restarted.
pause
goto menu

:createdb
cls
echo [Create Database]
set "DbName="
set "DbOwner="
set /p "DbName=Enter database name: "
if "%DbName%"=="" goto menu
bin\pg_ctl -D "%ClusterName%" status >nul 2>&1
if %errorlevel% NEQ 0 bin\pg_ctl -D "%ClusterName%" start
set /p "DbOwner=Owner (empty=postgres): "
if "%DbOwner%"=="" (
    bin\psql -h localhost -U postgres -c "CREATE DATABASE %DbName%;"
) else (
    bin\psql -h localhost -U postgres -c "CREATE DATABASE %DbName% OWNER %DbOwner%;"
)
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
bin\pg_ctl -D "%ClusterName%" status >nul 2>&1
if %errorlevel% NEQ 0 bin\pg_ctl -D "%ClusterName%" start
bin\psql -h localhost -U postgres -c "CREATE USER %NewUser% WITH PASSWORD '%NewPass%';"
set "TargetDb="
set /p "TargetDb=Grant to database (empty=skip): "
if not "%TargetDb%"=="" (
    bin\psql -h localhost -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE %TargetDb% TO %NewUser%;"
)
echo [Done] User %NewUser% created.
pause
goto menu

:listdb
cls
echo [List Databases]
bin\pg_ctl -D "%ClusterName%" status >nul 2>&1
if %errorlevel% NEQ 0 bin\pg_ctl -D "%ClusterName%" start
bin\psql -h localhost -U postgres -c "\l"
pause
goto menu

:listuser
cls
echo [List Users]
bin\pg_ctl -D "%ClusterName%" status >nul 2>&1
if %errorlevel% NEQ 0 bin\pg_ctl -D "%ClusterName%" start
bin\psql -h localhost -U postgres -c "\du"
pause
goto menu
