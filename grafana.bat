@echo off

:: Configuración inicial
set BASE_DIR=%~dp0grafana_setup
set GRAFANA_ZIP_NAME=grafana.zip
set GRAFANA_VERSION=9.4.7
set USER=admin
set PASSWORD=admin

:: Crear o limpiar la carpeta principal
if exist "%BASE_DIR%" (
    echo Limpiando carpeta existente...
    rmdir /s /q "%BASE_DIR%"
)
echo Creando carpeta principal...
mkdir "%BASE_DIR%"
cd "%BASE_DIR%"

:: Descargar Grafana
echo =====================================
echo Descargando Grafana...
echo =====================================
curl -k -L https://dl.grafana.com/oss/release/grafana-%GRAFANA_VERSION%.windows-amd64.zip -o "%GRAFANA_ZIP_NAME%"
if not exist "%GRAFANA_ZIP_NAME%" (
    echo Error: No se pudo descargar Grafana.
    pause
    exit /b
)

:: Extraer Grafana
echo =====================================
echo Extrayendo Grafana...
echo =====================================
powershell -Command "Expand-Archive -Path \"%cd%\%GRAFANA_ZIP_NAME%\" -DestinationPath \"%cd%\" -Force"
echo Contenido de la carpeta %BASE_DIR%:
dir "%BASE_DIR%"

:: Identificar carpeta extraída
echo =====================================
echo Buscando carpeta extraída de Grafana...
echo =====================================
for /d %%D in (%BASE_DIR%\grafana-*) do set GRAFANA_DIR=%%D
if not defined GRAFANA_DIR (
    echo Error: No se encontró la carpeta extraída de Grafana.
    pause
    exit /b
)
echo Carpeta encontrada: %GRAFANA_DIR%

:: Verificar bin y grafana-server.exe
echo Contenido de la carpeta bin:
dir "%GRAFANA_DIR%\bin"
if not exist "%GRAFANA_DIR%\bin\grafana-server.exe" (
    echo Error: No se encontró el ejecutable grafana-server.exe.
    pause
    exit /b
)

:: Iniciar Grafana desde la carpeta correcta con privilegios de administrador
echo =====================================
echo Iniciando Grafana Server como Administrador...
echo =====================================
pushd "%GRAFANA_DIR%\bin"
powershell -Command "Start-Process -FilePath 'grafana-server.exe' -Verb RunAs"
timeout /t 10 >nul
popd

:: Configurar usuario y contraseña en Grafana
echo =====================================
echo Configurando usuario y contraseña en Grafana...
echo =====================================
curl -X POST http://localhost:3000/api/admin/users ^
    -H "Content-Type: application/json" ^
    -d "{\"name\":\"%USER%\",\"email\":\"admin@example.com\",\"login\":\"%USER%\",\"password\":\"%PASSWORD%\"}"

:: Verificar si Grafana se está ejecutando correctamente
echo =====================================
echo Verificando estado de Grafana...
echo =====================================
curl -I http://localhost:3000
if errorlevel 1 (
    echo Error: Grafana no está activo en el puerto 3000.
    pause
    exit /b
)

echo =====================================
echo Grafana está configurado y en ejecución.
echo =====================================
pause
exit
