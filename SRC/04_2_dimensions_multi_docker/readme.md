
# Simulación de Líquidos Simples usando Ornstein-Zernike en Julia con Docker

Este proyecto permite ejecutar simulaciones para líquidos simples con el paquete `OrnsteinZernike.jl`, calculando la función de distribución radial \( g(r) \) para diferentes densidades, dimensiones y temperaturas \( k_B T \) usando un contenedor Docker.

---

## 📁 Archivos principales

1. **`density.jl`**  
   Script en Julia que realiza la simulación. Ver código completo en la sección "Anexo: Script Julia".

2. **`entrypoint.sh`**  
   Script Bash que valida variables y ejecuta el script de Julia.

3. **`Dockerfile`**  
   Construye la imagen Docker con Julia y las dependencias necesarias.

4. **`docker-compose.yml`**  
   Define el servicio Docker para levantar el contenedor.

5. **`.env`**  
   Contiene las variables de entorno necesarias para la simulación.

```env
DENSITIES=0.1,0.2,0.3,0.4,0.5,0.6
DIMENSION=2
KBT=1.0
FOLDER_NAME=resultados_density
```

También puedes usar directamente en consola:

```bash
export DENSITIES=0.1,0.2,0.3,0.4,0.5,0.6
export DIMENSION=2
export KBT=1.0
export FOLDER_NAME=resultados_density
docker compose up --build --force-recreate
```

---

## ▶️ Cómo usarlo

1. Instala Docker y Docker Compose.
2. Coloca todos los archivos en un mismo directorio.
3. (Opcional) Crea una carpeta local para resultados:

```bash
mkdir -p output_local
```

4. Ejecuta Docker Compose según tu sistema operativo:

### Linux / macOS:

```bash
DENSITIES="0.1,0.2,0.3,0.4,0.5,0.6" DIMENSION=2 KBT=1.0 FOLDER_NAME=resultados_density docker compose up --build --force-recreate
```

### Windows PowerShell:

```powershell
$env:DENSITIES="0.1,0.2,0.3,0.4,0.5,0.6"; $env:DIMENSION="2"; $env:KBT="1.0"; $env:FOLDER_NAME="resultados_density"; docker compose up --build --force-recreate
```

### Windows CMD:

```cmd
set DENSITIES=0.1,0.2,0.3,0.4,0.5,0.6&& set DIMENSION=2&& set KBT=1.0&& set FOLDER_NAME=resultados_density&& docker compose up --build --force-recreate
```

---

## 🧪 Ejemplos de ejecución avanzados

```bash
export DENSITIES=0.11,0.21,0.31,0.41,0.51,0.61,0.7
export DIMENSION=2
export KBT=1.0
export N_STAGES=10
export FOLDER_NAME=nuevo1
docker compose up --build --force-recreate
```

---

## 📂 Resultados

Los resultados se guardan en:

- Carpeta local: `output_local/resultados_density/`
- Volumen Docker: `volumen_lanimfe`

---

## 🐳 `docker-compose.yml`

```yaml
services:
  ornstein-zernike:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: density
    volumes:
      - ./:/workspace
      - ./output_local:/workspace/output
      - volumen_lanimfe:/data_output
    working_dir: /workspace
    environment:
      - DENSITIES=${DENSITIES}
      - DIMENSION=${DIMENSION}
      - KBT=${KBT}
      - FOLDER_NAME=${FOLDER_NAME}
    entrypoint: ["bash", "./entrypoint.sh"]

volumes:
  volumen_lanimfe:
```

---

## 🧱 `Dockerfile`

```Dockerfile
FROM julia:1.11

RUN apt-get update && apt-get install -y \
    bash curl wget git build-essential libcurl4-openssl-dev ca-certificates dos2unix \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

RUN git clone https://github.com/IlianPihlajamaa/OrnsteinZernike.jl

RUN julia -e 'using Pkg; Pkg.add(PackageSpec(path="OrnsteinZernike.jl")); Pkg.instantiate()'
RUN julia -e 'using Pkg; Pkg.add("JSON"); Pkg.add("DelimitedFiles")'

COPY density.jl /workspace/power_dockerduo.jl
COPY entrypoint.sh /workspace/entrypoint.sh

RUN dos2unix /workspace/entrypoint.sh && chmod +x /workspace/entrypoint.sh

ENTRYPOINT ["bash", "/workspace/entrypoint.sh"]
```

---

## 🚀 `entrypoint.sh`

```bash
#!/bin/bash
set -euo pipefail

if [ -z "${DENSITIES:-}" ] || [ -z "${DIMENSION:-}" ] || [ -z "${KBT:-}" ] || [ -z "${FOLDER_NAME:-}" ]; then
  echo "ERROR: Faltan variables de entorno requeridas."
  echo "Define densidades, dimensiones, KBT y FOLDER_NAME en el archivo .env o al ejecutar el contenedor."
  exit 1
fi

echo "Densities: $DENSITIES"
echo "Dimension: $DIMENSION"
echo "KBT: $KBT"
echo "Folder Name: $FOLDER_NAME"
echo ""

LOCAL_PATH="/workspace/$FOLDER_NAME"
VOLUME_PATH="/data_output/$FOLDER_NAME"

mkdir -p "$LOCAL_PATH"
mkdir -p "$VOLUME_PATH"

echo "Local Path: $LOCAL_PATH"
echo "Volume Path: $VOLUME_PATH"
echo ""

command -v julia >/dev/null 2>&1 || { echo >&2 "Julia no está instalada."; exit 1; }

julia density.jl "$DENSITIES" "$DIMENSION" "$KBT" "$LOCAL_PATH" "$VOLUME_PATH"
```

---

## 📜 Anexo: Script Julia (`density.jl`)

[Haz clic para ver el código completo del script `density.jl`](#)
