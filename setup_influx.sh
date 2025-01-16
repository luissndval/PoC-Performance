#!/bin/bash

# Configuración inicial
BASE_DIR="$(pwd)/influxdb_setup"
INFLUXDB_ZIP_NAME="influxdb.tar.gz"
INFLUXDB_VERSION="1.7.9"
USER="admin"
PASSWORD="admin"
ORG="default_org"
BUCKET="default_bucket"

# Crear o limpiar la carpeta principal
if [ -d "$BASE_DIR" ]; then
    echo "Limpiando carpeta existente..."
    rm -rf "$BASE_DIR"
fi
echo "Creando carpeta principal..."
mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

# Descargar InfluxDB
echo "====================================="
echo "Descargando InfluxDB..."
echo "====================================="
curl -k -L https://dl.influxdata.com/influxdb/releases/influxdb-${INFLUXDB_VERSION}-darwin-amd64.tar.gz -o "$INFLUXDB_ZIP_NAME"
if [ ! -f "$INFLUXDB_ZIP_NAME" ]; then
    echo "Error: No se pudo descargar InfluxDB."
    exit 1
fi

# Extraer InfluxDB
echo "====================================="
echo "Extrayendo InfluxDB..."
echo "====================================="
tar -xzf "$INFLUXDB_ZIP_NAME" -C "$BASE_DIR"
if [ $? -ne 0 ]; then
    echo "Error: No se pudo extraer el archivo ZIP."
    exit 1
fi

# Verificar carpeta extraída
echo "====================================="
echo "Verificando carpeta extraída..."
echo "====================================="
INFLUXDB_DIR=$(find "$BASE_DIR" -type d -name "*influxdb*")
if [ -z "$INFLUXDB_DIR" ]; then
    echo "Error: No se encontró la carpeta de InfluxDB."
    exit 1
fi
echo "Carpeta encontrada: $INFLUXDB_DIR"

# Iniciar InfluxDB
echo "====================================="
echo "Iniciando InfluxDB..."
echo "====================================="
"$INFLUXDB_DIR/influxd" &
sleep 10

# Crear la base de datos PoC
echo "====================================="
echo "Creando la base de datos PoC..."
echo "====================================="
"$INFLUXDB_DIR/influx" -execute "CREATE DATABASE PoC"
if [ $? -ne 0 ]; then
    echo "Error: No se pudo crear la base de datos PoC."
    exit 1
fi
echo "Base de datos PoC creada exitosamente."

# Verificar que la base de datos funciona bien
echo "====================================="
echo "Verificando la base de datos PoC..."
echo "====================================="
DB_EXISTS=$("$INFLUXDB_DIR/influx" -execute "SHOW DATABASES" | grep -c "PoC")
if [ "$DB_EXISTS" -eq 0 ]; then
    echo "Error: No se pudo verificar la base de datos PoC."
    exit 1
fi
echo "La base de datos PoC está funcionando correctamente."

# Confirmación final
echo "====================================="
echo "InfluxDB y la base de datos PoC están configurados y en ejecución."
echo "====================================="
exit 0
