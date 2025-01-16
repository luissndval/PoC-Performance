#!/bin/bash

# Configuración inicial
BASE_DIR="$(pwd)/grafana_setup"
GRAFANA_ZIP_NAME="grafana.zip"
GRAFANA_VERSION="9.4.7"
USER="admin"
PASSWORD="admin"

# Crear o limpiar la carpeta principal
if [ -d "$BASE_DIR" ]; then
    echo "Limpiando carpeta existente..."
    rm -rf "$BASE_DIR"
fi
echo "Creando carpeta principal..."
mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

# Descargar Grafana
echo "====================================="
echo "Descargando Grafana..."
echo "====================================="
curl -k -L "https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.darwin-amd64.tar.gz" -o "$GRAFANA_ZIP_NAME"
if [ ! -f "$GRAFANA_ZIP_NAME" ]; then
    echo "Error: No se pudo descargar Grafana."
    exit 1
fi

# Extraer Grafana
echo "====================================="
echo "Extrayendo Grafana..."
echo "====================================="
tar -xzf "$GRAFANA_ZIP_NAME" -C "$BASE_DIR"
if [ $? -ne 0 ]; then
    echo "Error: No se pudo extraer el archivo."
    exit 1
fi

# Verificar carpeta extraída
echo "====================================="
echo "Buscando carpeta extraída de Grafana..."
echo "====================================="
GRAFANA_DIR=$(find "$BASE_DIR" -type d -name "grafana-*")
if [ -z "$GRAFANA_DIR" ]; then
    echo "Error: No se encontró la carpeta extraída de Grafana."
    exit 1
fi
echo "Carpeta encontrada: $GRAFANA_DIR"

# Verificar bin y grafana-server
echo "Contenido de la carpeta bin:"
ls "$GRAFANA_DIR/bin"
if [ ! -f "$GRAFANA_DIR/bin/grafana-server" ]; then
    echo "Error: No se encontró el ejecutable grafana-server."
    exit 1
fi

# Iniciar Grafana desde la carpeta correcta
echo "====================================="
echo "Iniciando Grafana Server..."
echo "====================================="
"$GRAFANA_DIR/bin/grafana-server" &

# Verificar si Grafana se está ejecutando correctamente
sleep 10
echo "====================================="
echo "Verificando estado de Grafana..."
echo "====================================="
curl -I http://localhost:3000
if [ $? -ne 0 ]; then
    echo "Error: Grafana no está activo en el puerto 3000."
    exit 1
fi

# Configurar usuario y contraseña en Grafana
echo "====================================="
echo "Configurando usuario y contraseña en Grafana..."
echo "====================================="
curl -X POST http://localhost:3000/api/admin/users \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$USER\",\"email\":\"admin@example.com\",\"login\":\"$USER\",\"password\":\"$PASSWORD\"}"

# Confirmación final
echo "====================================="
echo "Grafana está configurado y en ejecución."
echo "====================================="
exit 0
