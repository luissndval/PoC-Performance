@echo off

:: Configuración inicial
set BASE_DIR=%~dp0influxdb_setup
set INFLUXDB_ZIP_NAME=influxdb.zip
set INFLUXDB_VERSION=1.7.9
set USER=admin
set PASSWORD=admin
set ORG=default_org
set BUCKET=default_bucket

:: Crear o limpiar la carpeta principal
if exist "%BASE_DIR%" (
    echo Limpiando carpeta existente...
    rmdir /s /q "%BASE_DIR%"
)
echo Creando carpeta principal...
mkdir "%BASE_DIR%"
cd "%BASE_DIR%"

:: Descargar InfluxDB
echo =====================================
echo Descargando InfluxDB...
echo =====================================
curl -k -L https://dl.influxdata.com/influxdb/releases/influxdb-%INFLUXDB_VERSION%_windows_amd64.zip -o "%INFLUXDB_ZIP_NAME%"
if not exist "%INFLUXDB_ZIP_NAME%" (
    echo Error: No se pudo descargar InfluxDB.
    pause
    exit /b
)

:: Extraer InfluxDB
echo =====================================
echo Extrayendo InfluxDB...
echo =====================================
powershell -Command "Expand-Archive -Path \"%cd%\%INFLUXDB_ZIP_NAME%\" -DestinationPath \"%cd%\" -Force"
echo Contenido de la carpeta %BASE_DIR%:
if errorlevel 1 (
    echo Error: No se pudo extraer el archivo ZIP.
    pause
    exit /b
)

:: Extraer InfluxDB o verificar carpeta existente
echo =====================================
echo Verificando o extrayendo InfluxDB...
echo =====================================
for /d %%D in (%BASE_DIR%\*influx*) do (
    set INFLUXDB_DIR=%%D
    goto FolderFound
)

:: Si no se encuentra una carpeta existente, se extrae el archivo ZIP
echo Carpeta no detectada, extrayendo archivo ZIP...
tar -xf "%INFLUXDB_ZIP_NAME%" -C "%BASE_DIR%"
if errorlevel 1 (
    echo Error: Falló la extracción del archivo ZIP.
    pause
    exit /b
)

for /d %%D in (%BASE_DIR%\*influx*) do set INFLUXDB_DIR=%%D

:FolderFound
if not defined INFLUXDB_DIR (
    echo Error: No se encontró la carpeta de InfluxDB.
    pause
    exit /b
)
echo Carpeta encontrada: %INFLUXDB_DIR%

:: Iniciar InfluxDB desde la carpeta correcta con privilegios de administrador
echo =====================================
echo Iniciando InfluxDB Server como Administrador...
echo =====================================
pushd "%INFLUXDB_DIR%"
powershell -Command "Start-Process -FilePath 'influxd.exe' -Verb RunAs"
timeout /t 10 >nul
popd

:: Crear la base de datos PoC
echo =====================================
echo Creando la base de datos PoC...
echo =====================================
pushd "%INFLUXDB_DIR%"
"%INFLUXDB_DIR%\influx.exe" -execute "CREATE DATABASE PoC"
if errorlevel 1 (
    echo Error: No se pudo crear la base de datos PoC.
    pause
    exit /b
)
echo Base de datos PoC creada exitosamente.
popd

:: Verificar que la base de datos funciona bien
echo =====================================
echo Verificando la base de datos PoC...
echo =====================================
pushd "%INFLUXDB_DIR%"
"%INFLUXDB_DIR%\influx.exe" -execute "SHOW DATABASES" | find "PoC" >nul
if errorlevel 1 (
    echo Error: No se pudo verificar la base de datos PoC.
    pause
    exit /b
)
echo La base de datos PoC está funcionando correctamente.
popd

:: Confirmación final
echo =====================================
echo InfluxDB y la base de datos PoC están configurados y en ejecución.
echo =====================================
pause
exit
