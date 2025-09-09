#!/usr/bin/env bash
set -Eeuo pipefail

MODE="${1:-auto}"   # auto | start | install | stop | status

# ---------- Config ----------
GRAFANA_VERSION="9.4.7"
INFLUXDB_VERSION="1.11.8"
INFLUXDB_DB_NAME="PoC"
INFLUXDB_PORT=8086
GRAFANA_PORT=3000
GRAFANA_CREDENTIALS="admin:admin"

BASE_DIR="$(pwd)"
GRAFANA_BASE_DIR="$BASE_DIR/grafana_setup"
INFLUXDB_BASE_DIR="$BASE_DIR/influxdb_setup"

GRAFANA_TGZ="grafana-${GRAFANA_VERSION}.darwin-amd64.tar.gz"
GRAFANA_URL="https://dl.grafana.com/oss/release/${GRAFANA_TGZ}"

INFLUX_TGZ="influxdb-${INFLUXDB_VERSION}-darwin-amd64.tar.gz"
INFLUX_URL="https://download.influxdata.com/influxdb/releases/${INFLUX_TGZ}"

# (Se pueden sobreescribir por env si ya tienes instalaciones en otro lado)
: "${GRAFANA_HOME:="$GRAFANA_BASE_DIR/grafana-${GRAFANA_VERSION}"}"
: "${GRAFANA_LOG:="/tmp/grafana.log"}"
: "${INFLUXDB_DIR:="$INFLUXDB_BASE_DIR/influxdb-${INFLUXDB_VERSION}-darwin-amd64"}"
: "${INFLUXDB_LOG:="/tmp/influxdb.log"}"

GRAFANA_BIN=""
INFLUXD_BIN=""
INFLUX_CLI=""

# ---------- Helpers ----------
port_up() { lsof -i ":$1" &>/dev/null; }
http_ok() { curl -sf "$1" >/dev/null; }
die() { echo "Error: $*" >&2; exit 1; }

detect_grafana() {
  if command -v grafana-server &>/dev/null; then
    GRAFANA_BIN="$(command -v grafana-server)"
    return
  fi
  if [[ -x "$GRAFANA_HOME/bin/grafana-server" ]]; then
    GRAFANA_BIN="$GRAFANA_HOME/bin/grafana-server"
    return
  fi
  GRAFANA_BIN=""
}

detect_influx1() {
  if command -v influxd &>/dev/null; then
    INFLUXD_BIN="$(command -v influxd)"
    # Validar mayor 1.x
    if "$INFLUXD_BIN" version 2>/dev/null | grep -Eq '(^| )v?1\.'; then
      :
    else
      die "Se detectó influxd pero no es 1.x. Este script está preparado para InfluxDB 1.x."
    fi
  elif [[ -x "$INFLUXDB_DIR/influxd" ]]; then
    INFLUXD_BIN="$INFLUXDB_DIR/influxd"
  else
    INFLUXD_BIN=""
  fi

  if command -v influx &>/dev/null; then
    INFLUX_CLI="$(command -v influx)"
  elif [[ -x "$INFLUXDB_DIR/influx" ]]; then
    INFLUX_CLI="$INFLUXDB_DIR/influx"
  else
    INFLUX_CLI=""
  fi
}

install_grafana() {
  echo "== Instalando Grafana ${GRAFANA_VERSION} =="
  rm -rf "$GRAFANA_BASE_DIR"; mkdir -p "$GRAFANA_BASE_DIR"
  curl -L "$GRAFANA_URL" -o "$GRAFANA_BASE_DIR/$GRAFANA_TGZ"
  tar -xzf "$GRAFANA_BASE_DIR/$GRAFANA_TGZ" -C "$GRAFANA_BASE_DIR"
  detect_grafana
  [[ -n "$GRAFANA_BIN" ]] || die "grafana-server no encontrado tras la instalación"
}

install_influx1() {
  echo "== Instalando InfluxDB ${INFLUXDB_VERSION} (1.x) =="
  rm -rf "$INFLUXDB_BASE_DIR"; mkdir -p "$INFLUXDB_BASE_DIR"
  curl -L "$INFLUX_URL" -o "$INFLUXDB_BASE_DIR/$INFLUX_TGZ"
  tar -xf "$INFLUXDB_BASE_DIR/$INFLUX_TGZ" -C "$INFLUXDB_BASE_DIR"
  chmod +x "$INFLUXDB_DIR/influxd" "$INFLUXDB_DIR/influx"
  detect_influx1
  [[ -n "$INFLUXD_BIN" && -n "$INFLUX_CLI" ]] || die "No se encontraron binarios de Influx 1.x tras la instalación"
}

start_grafana() {
  echo "== Iniciando Grafana =="
  detect_grafana
  [[ -n "$GRAFANA_BIN" ]] || die "Grafana no está instalado. Ejecuta: $0 install"
  if port_up "$GRAFANA_PORT"; then
    echo "Grafana ya está escuchando en :$GRAFANA_PORT"
    return
  fi
  export GF_SECURITY_ADMIN_USER="admin"
  export GF_SECURITY_ADMIN_PASSWORD="admin"
  # Si es tarball, pasar --homepath; si es sistema, no hace falta
  if [[ -x "$GRAFANA_HOME/bin/grafana-server" && "$GRAFANA_BIN" == "$GRAFANA_HOME/bin/grafana-server" ]]; then
    nohup "$GRAFANA_BIN" --homepath="$GRAFANA_HOME" >"$GRAFANA_LOG" 2>&1 &
  else
    nohup "$GRAFANA_BIN" >"$GRAFANA_LOG" 2>&1 &
  fi
  # Esperar health
  for i in {1..30}; do
    if http_ok "http://localhost:${GRAFANA_PORT}/api/health"; then
      echo "Grafana OK en http://localhost:${GRAFANA_PORT}"
      return
    fi
    sleep 1
  done
  die "Grafana no respondió saludable en tiempo esperado. Revisa $GRAFANA_LOG"
}

start_influx1() {
  echo "== Iniciando InfluxDB 1.x =="
  detect_influx1
  [[ -n "$INFLUXD_BIN" && -n "$INFLUX_CLI" ]] || die "InfluxDB 1.x no está instalado. Ejecuta: $0 install"
  if port_up "$INFLUXDB_PORT"; then
    echo "InfluxDB ya está escuchando en :$INFLUXDB_PORT"
  else
    nohup "$INFLUXD_BIN" >"$INFLUXDB_LOG" 2>&1 &
    # Esperar ping
    for i in {1..30}; do
      if curl -sf "http://localhost:${INFLUXDB_PORT}/ping" >/dev/null; then
        break
      fi
      sleep 1
    done
    curl -sf "http://localhost:${INFLUXDB_PORT}/ping" >/dev/null || die "InfluxDB no respondió /ping. Revisa $INFLUXDB_LOG"
  fi
  # Crear DB si no existe (solo 1.x)
  if ! "$INFLUX_CLI" -host 127.0.0.1 -port "${INFLUXDB_PORT}" -execute "SHOW DATABASES" 2>/dev/null | grep -q "^${INFLUXDB_DB_NAME}$"; then
    "$INFLUX_CLI" -host 127.0.0.1 -port "${INFLUXDB_PORT}" -execute "CREATE DATABASE ${INFLUXDB_DB_NAME}" \
      || die "No se pudo crear DB ${INFLUXDB_DB_NAME}"
    echo "DB creada: ${INFLUXDB_DB_NAME}"
  else
    echo "DB ${INFLUXDB_DB_NAME} ya existe"
  fi
}

ensure_grafana_datasource() {
  echo "== Asegurando DataSource InfluxDB en Grafana =="
  # ¿Existe?
  code=$(curl -su "$GRAFANA_CREDENTIALS" -o /dev/null -w "%{http_code}" \
    "http://localhost:${GRAFANA_PORT}/api/datasources/name/InfluxDB" || true)
  if [[ "$code" == "200" ]]; then
    echo "DataSource 'InfluxDB' ya existe (no se toca)."
    return
  fi
  # Crear
  curl -sS -u "$GRAFANA_CREDENTIALS" -H "Content-Type: application/json" -X POST \
    -d "{
      \"name\": \"InfluxDB\",
      \"type\": \"influxdb\",
      \"access\": \"proxy\",
      \"url\": \"http://localhost:${INFLUXDB_PORT}\",
      \"database\": \"${INFLUXDB_DB_NAME}\",
      \"user\": \"\",
      \"password\": \"\",
      \"basicAuth\": false,
      \"isDefault\": true
    }" "http://localhost:${GRAFANA_PORT}/api/datasources" >/dev/null \
    || die "No se pudo crear el DataSource en Grafana"
  echo "DataSource creado: InfluxDB -> http://localhost:${INFLUXDB_PORT}/${INFLUXDB_DB_NAME}"
}

status() {
  echo "== Status =="
  if port_up "$GRAFANA_PORT"; then
    echo "Grafana: UP (:${GRAFANA_PORT})"
  else
    echo "Grafana: DOWN"
  fi
  if port_up "$INFLUXDB_PORT"; then
    echo "InfluxDB: UP (:${INFLUXDB_PORT})"
  else
    echo "InfluxDB: DOWN"
  fi
}

stop_port() {
  local p="$1"
  if port_up "$p"; then
    local pid
    pid="$(lsof -t -i ":$p" || true)"
    if [[ -n "${pid:-}" ]]; then
      kill "$pid" || true
      sleep 1
      if port_up "$p"; then kill -9 "$pid" || true; fi
      echo "Detenido proceso en puerto :$p (PID ${pid})"
    fi
  fi
}

stop_all() {
  echo "== Deteniendo servicios =="
  stop_port "$GRAFANA_PORT"
  stop_port "$INFLUXDB_PORT"
}

# ---------- Flow ----------
case "$MODE" in
  install)
    install_grafana
    install_influx1
    start_influx1
    start_grafana
    ensure_grafana_datasource
    ;;
  start)
    start_influx1
    start_grafana
    ensure_grafana_datasource
    ;;
  status)
    status
    ;;
  stop)
    stop_all
    ;;
  auto|*)
    # Si ya hay binarios, no reinstala. Si faltan, instala lo que falte.
    detect_grafana
    detect_influx1
    [[ -z "$GRAFANA_BIN" ]] && install_grafana
    [[ -z "$INFLUXD_BIN" || -z "$INFLUX_CLI" ]] && install_influx1
    start_influx1
    start_grafana
    ensure_grafana_datasource
    ;;
esac

echo "Listo ✔  Grafana: http://localhost:${GRAFANA_PORT} | InfluxDB 1.x: http://localhost:${INFLUXDB_PORT}"
