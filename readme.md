# Setup de Grafana e InfluxDB

Este repositorio contiene un script que automatiza la instalación, configuración y ejecución de **Grafana** e **InfluxDB** en sistemas macOS y Windows. Además, configura la integración entre ambos sistemas, agregando InfluxDB como una fuente de datos en Grafana.

---

## **Descripción del Script**

El script realiza las siguientes tareas:

1. Descarga e instala **Grafana** y **InfluxDB** en las rutas configuradas.
2. Inicia ambos servicios:
   - **Grafana** se ejecuta en el puerto `3000` y está disponible en `http://localhost:3000`.
   - **InfluxDB** se ejecuta en el puerto `8086` y está disponible en `http://localhost:8086`.
3. Configura una base de datos llamada `PoC` en InfluxDB.
4. Agrega automáticamente InfluxDB como una fuente de datos predeterminada en Grafana.

---

## **Requisitos**

### **macOS**
- Tener instalado:
  - `bash`
  - `curl`
  - `tar`
  - `awk`
  - `lsof`

### **Windows**
- Tener instalado:
  - Un entorno de bash (recomendado: [Git Bash](https://gitforwindows.org/) o WSL).
  - `curl`.

---

## **Ejecución**

### **macOS**
1. Clona este repositorio:
   ```bash
   git clone https://github.com/luissndval/PoC-Performance.git
   cd PoC-Performance
   ```
2. Da permisos de ejecución al script:
   ```bash
   chmod +x setup_grafana_and_influxdb.sh
   ```
3. Ejecuta el script:
   ```bash
   ./setup_grafana_and_influxdb.sh
   ```

### **Windows**
1. Clona este repositorio:
   - Abre una terminal (por ejemplo, Git Bash o WSL) y ejecuta:
     ```bash
     git clone https://github.com/luissndval/PoC-Performance.git
     cd PoC-Performance
     ```
2. Ejecuta el script:
   ```bash
   bash setup_grafana_and_influxdb.sh
   ```

### **Ejecutar cualquier archivo .sh**
1. **macOS y Linux**:
   - Da permisos de ejecución al archivo con:
     ```bash
     chmod +x nombre_del_script.sh
     ```
   - Ejecuta el script con:
     ```bash
     ./nombre_del_script.sh
     ```
2. **Windows**:
   - Si usas Git Bash o WSL, ejecuta el script directamente con:
     ```bash
     bash nombre_del_script.sh
     ```

---

## **URLs y Puertos Predeterminados**

| Servicio | URL                         | Puerto | Descripción                              |
|----------|-----------------------------|--------|------------------------------------------|
| Grafana  | `http://localhost:3000`     | 3000   | Interfaz web para visualización de datos.|
| InfluxDB | `http://localhost:8086`     | 8086   | API de base de datos para almacenamiento.|

---

## **Estructura del Repositorio**

```
PoC-Performance/
├── setup_grafana_and_influxdb.sh    # Script principal
├── README.md                        # Este archivo
```

---

## **Qué hace el script**

### **Grafana**
1. Descarga la versión `9.4.7` de Grafana desde:
   [https://dl.grafana.com/oss/release/grafana-9.4.7.darwin-amd64.tar.gz](https://dl.grafana.com/oss/release/grafana-9.4.7.darwin-amd64.tar.gz).
2. Extrae los archivos en el directorio `grafana_setup`.
3. Configura credenciales predeterminadas:
   - Usuario: `admin`
   - Contraseña: `admin`
4. Inicia Grafana en el puerto `3000`.

### **InfluxDB**
1. Descarga la versión `1.11.8` de InfluxDB desde:
   [https://download.influxdata.com/influxdb/releases/influxdb-1.11.8-darwin-amd64.tar.gz](https://download.influxdata.com/influxdb/releases/influxdb-1.11.8-darwin-amd64.tar.gz).
2. Extrae los archivos en el directorio `influxdb_setup`.
3. Crea una base de datos llamada `PoC`.
4. Inicia InfluxDB en el puerto `8086`.

### **Integración**
1. Usa la API de Grafana para agregar InfluxDB como una fuente de datos predeterminada.
   - Nombre de la fuente de datos: `InfluxDB`.
   - URL configurada: `http://localhost:8086`.
   - Base de datos configurada: `PoC`.

---

## **Detener los servicios**

Para detener Grafana e InfluxDB, usa el script `stop_services.sh` incluido:

1. Da permisos de ejecución al script:
   ```bash
   chmod +x stop_services.sh
   ```
2. Ejecuta el script:
   ```bash
   ./stop_services.sh
   ```

Esto finalizará ambos servicios.

---

## **Notas**

- **Compatibilidad:** El script está diseñado para sistemas macOS y entornos bash compatibles en Windows.
- **Soporte:** Si encuentras problemas, por favor abre un [issue](https://github.com/luissndval/PoC-Performance/issues).

---

¡Gracias por usar este repositorio!

