#!/bin/bash

# Configuración inicial para Grafana
GRAFANA_BASE_DIR="$(pwd)/grafana_setup"
GRAFANA_ZIP_NAME="grafana.tar.gz"
GRAFANA_VERSION="9.4.7"
GRAFANA_DOWNLOAD_URL="https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.darwin-amd64.tar.gz"
GRAFANA_API_URL="http://localhost:3000/api/datasources"
GRAFANA_CREDENTIALS="admin:admin"

# Configuración inicial para InfluxDB
INFLUXDB_BASE_DIR="$(pwd)/influxdb_setup"
INFLUXDB_VERSION="1.11.8"
INFLUXDB_TAR_NAME="influxdb-${INFLUXDB_VERSION}-darwin-amd64.tar.gz"
INFLUXDB_DOWNLOAD_URL="https://download.influxdata.com/influxdb/releases/${INFLUXDB_TAR_NAME}"
INFLUXDB_DB_NAME="PoC"
INFLUXDB_PORT=8086

# Función para instalar Grafana
install_grafana() {
    echo "====================================="
    echo "Instalando Grafana ${GRAFANA_VERSION}..."
    echo "====================================="

    # Limpiar o crear la carpeta principal
    if [ -d "$GRAFANA_BASE_DIR" ]; then
        echo "Limpiando carpeta existente..."
        rm -rf "$GRAFANA_BASE_DIR"
    fi
    mkdir -p "$GRAFANA_BASE_DIR"

    # Descargar Grafana
    curl -L "$GRAFANA_DOWNLOAD_URL" -o "$GRAFANA_BASE_DIR/$GRAFANA_ZIP_NAME"
    if [ ! -f "$GRAFANA_BASE_DIR/$GRAFANA_ZIP_NAME" ]; then
        echo "Error: No se pudo descargar Grafana."
        exit 1
    fi

    # Extraer Grafana
    tar -xzf "$GRAFANA_BASE_DIR/$GRAFANA_ZIP_NAME" -C "$GRAFANA_BASE_DIR"
    GRAFANA_DIR="$GRAFANA_BASE_DIR/grafana-${GRAFANA_VERSION}"
    if [ ! -d "$GRAFANA_DIR" ]; then
        echo "Error: No se encontró la carpeta extraída de Grafana."
        exit 1
    fi

    # Verificar la carpeta `bin`
    if [ ! -d "$GRAFANA_DIR/bin" ]; then
        echo "Error: El directorio 'bin' no se encontró en $GRAFANA_DIR. Verifica la descarga."
        exit 1
    fi

    # Configurar usuario y contraseña predeterminados
    export GF_SECURITY_ADMIN_USER="admin"
    export GF_SECURITY_ADMIN_PASSWORD="admin"

    # Ejecutar el servidor de Grafana
    cd "$GRAFANA_DIR/bin"
    ./grafana-server --homepath="$GRAFANA_DIR" > grafana.log 2>&1 &
    GRAFANA_PID=$!
    echo "Grafana se está ejecutando en http://localhost:3000 con usuario 'admin' y contraseña 'admin'"
    sleep 10
}

# Función para instalar InfluxDB
install_influxdb() {
    echo "====================================="
    echo "Instalando InfluxDB ${INFLUXDB_VERSION}..."
    echo "====================================="

    # Limpiar o crear la carpeta principal
    if [ -d "$INFLUXDB_BASE_DIR" ]; then
        echo "Limpiando carpeta existente..."
        rm -rf "$INFLUXDB_BASE_DIR"
    fi
    mkdir -p "$INFLUXDB_BASE_DIR"
    cd "$INFLUXDB_BASE_DIR"

    # Descargar InfluxDB
    curl -L "$INFLUXDB_DOWNLOAD_URL" -o "$INFLUXDB_TAR_NAME"
    if [ ! -f "$INFLUXDB_TAR_NAME" ]; then
        echo "Error: No se pudo descargar InfluxDB."
        exit 1
    fi

    # Extraer InfluxDB
    tar -xf "$INFLUXDB_TAR_NAME" -C "$INFLUXDB_BASE_DIR"
    if [ ! -f "$INFLUXDB_BASE_DIR/influxd" ] || [ ! -f "$INFLUXDB_BASE_DIR/influx" ]; then
        echo "Error: No se encontraron los binarios de InfluxDB en $INFLUXDB_BASE_DIR."
        exit 1
    fi

    # Hacer ejecutables los binarios
    chmod +x "$INFLUXDB_BASE_DIR/influxd" "$INFLUXDB_BASE_DIR/influx"

    # Iniciar InfluxDB
    "$INFLUXDB_BASE_DIR/influxd" > "$INFLUXDB_BASE_DIR/influxdb.log" 2>&1 &
    INFLUXDB_PID=$!
    sleep 10

    # Verificar si el servidor está corriendo
    if ! lsof -i :$INFLUXDB_PORT &>/dev/null; then
        echo "Error: No se pudo iniciar InfluxDB en el puerto $INFLUXDB_PORT."
        kill $INFLUXDB_PID
        exit 1
    fi

    # Crear la base de datos
    "$INFLUXDB_BASE_DIR/influx" -execute "CREATE DATABASE $INFLUXDB_DB_NAME"
    if [ $? -ne 0 ]; then
        echo "Error: No se pudo crear la base de datos $INFLUXDB_DB_NAME."
        kill $INFLUXDB_PID
        exit 1
    fi

    echo "InfluxDB está disponible en: http://localhost:$INFLUXDB_PORT"
    echo "Base de datos creada: $INFLUXDB_DB_NAME"
}

# Función para agregar InfluxDB como fuente de datos en Grafana
add_influxdb_to_grafana() {
    echo "====================================="
    echo "Agregando InfluxDB como fuente de datos en Grafana..."
    echo "====================================="
    curl -X POST -H "Content-Type: application/json" -u "$GRAFANA_CREDENTIALS" \
        -d '{
            "name": "InfluxDB",
            "type": "influxdb",
            "access": "proxy",
            "url": "http://localhost:'"$INFLUXDB_PORT"'",
            "database": "'"$INFLUXDB_DB_NAME"'",
            "user": "",
            "password": "",
            "basicAuth": false,
            "isDefault": true
        }' "$GRAFANA_API_URL"

    if [ $? -eq 0 ]; then
        echo "InfluxDB se agregó correctamente a Grafana como fuente de datos."
    else
        echo "Error: No se pudo agregar InfluxDB como fuente de datos en Grafana."
    fi
}

# Llamar a las funciones de instalación
install_grafana
install_influxdb
add_influxdb_to_grafana

# Mensaje final
echo "====================================="
echo "Grafana e InfluxDB se han instalado y configurado correctamente."
echo "Grafana: http://localhost:3000 (admin/admin)"
echo "InfluxDB: http://localhost:$INFLUXDB_PORT"
echo "InfluxDB se ha agregado como fuente de datos en Grafana."
echo "====================================="
