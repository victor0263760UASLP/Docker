# 🧪 Simulación de Líquidos con Potencial Yukawa en Julia usando Docker

Este proyecto permite simular líquidos simples en 3D con potencial Yukawa utilizando la ecuación de Ornstein-Zernike. Se ejecuta fácilmente usando Docker y Docker Compose en Windows, macOS y Linux.

---

## 📂 Archivos del Proyecto

- `Rampa.jl`: Script principal en Julia que realiza la simulación.
- `entrypoint.sh`: Script Bash que valida variables, prepara carpetas y ejecuta el código de Julia.
- `Dockerfile`: Define la imagen de Docker con Julia, sus dependencias y el repositorio `OrnsteinZernike.jl`.
- `docker-compose.yml`: Orquesta la ejecución del contenedor y define volúmenes y variables.
- `.env`: Define los parámetros físicos y de ejecución. (Opcional)

---

## ⚙️ Variables de Entorno

Pueden definirse en un archivo `.env` o directamente al ejecutar el contenedor.

### Ejemplo de archivo `.env`

```env
SIGMA=144.0
Z=-440.0
KBT=0.59
PHI=0.00081
M=10000
N_STAGES=50
MAX_ITER=10000
CHI_LIST=0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.95,0.99
FOLDER_NAME=Rampa
```

---

## ▶️ Cómo Ejecutar la Simulación

### ✅ Requisitos previos

- Tener [Docker](https://www.docker.com/products/docker-desktop/) y [Docker Compose](https://docs.docker.com/compose/) instalados.

### Opción 1: Usando archivo `.env` (recomendado)

```bash
docker compose up --build --force-recreate
```

### Opción 2: Declarando variables en consola

#### 🔵 En Linux/macOS

```bash
SIGMA=144.0 Z=-440.0 KBT=0.59 PHI=0.00081 M=10000 N_STAGES=50 MAX_ITER=10000 CHI_LIST="0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.95,0.99" FOLDER_NAME=Rampa docker compose up --build --force-recreate
```

#### 🟣 En Windows (PowerShell)

```powershell
$env:SIGMA="144.0"
$env:Z="-440.0"
$env:KBT="0.59"
$env:PHI="0.00081"
$env:M="10000"
$env:N_STAGES="50"
$env:MAX_ITER="10000"
$env:CHI_LIST="0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.95,0.99"
$env:FOLDER_NAME="Rampa"
docker compose up --build --force-recreate
```

---


---

## 📄 Ejemplo de archivo `.env`

Puedes crear un archivo llamado `.env` en la raíz del proyecto con el siguiente contenido:

```env
SIGMA=144.0
Z=-440.0
KBT=0.59
PHI=0.00081
M=10000
N_STAGES=50
MAX_ITER=10000
CHI_LIST=0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.95,0.99
FOLDER_NAME=Rampa
```

Este archivo permite ejecutar el contenedor fácilmente sin tener que declarar manualmente las variables cada vez.

## 📁 Resultados

Los resultados se guardan en:

- Carpeta local: `./output_local/Rampa/`
- Volumen de Docker: `volumen_lanimfe`

Por cada etapa se generan los siguientes archivos:

- `gdr_phi_<valor>_<idx>.dat`: función de distribución radial \( g(r) \)
- `sdk_phi_<valor>_<idx>.dat`: factor de estructura \( S(k) \)

---

## 🧠 Requisitos Técnicos

- Docker + Docker Compose
- Julia ≥ 1.11 (ya instalada dentro del contenedor Docker)
- Repositorio: [OrnsteinZernike.jl](https://github.com/IlianPihlajamaa/OrnsteinZernike.jl)

---

## 📝 Autor

**Víctor Guadalupe Rivera Juárez**  
📅 9 de Junio del 2025

