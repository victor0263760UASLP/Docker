# 🧪 Simulación de Dinámica con SCGLE en Julia usando Docker

Este proyecto permite simular la dinámica de partículas en un líquido usando la **teoría SCGLE** (Self-Consistent Generalized Langevin Equation), implementada en Julia y contenida dentro de un entorno Docker.

---

## 📁 Estructura de Archivos

- `scgle.jl`: Código principal en Julia que ejecuta la simulación de Fs(k, t).
- `entrypoint.sh`: Script de entrada que valida las variables de entorno y ejecuta `scgle.jl`.
- `Dockerfile`: Crea la imagen Docker con Julia 1.11, clona dependencias, instala paquetes y configura el entorno.
- `docker-compose.yml`: Orquesta el servicio, los volúmenes, y las variables de entorno.
- `.env`: Archivo donde defines parámetros físicos como la fracción de volumen `PHI` y el nombre de carpeta de resultados `FOLDER_NAME`.

---

## ⚙️ Variables de Entorno (.env)

```env
# Parámetros para la simulación SCGLE

PHI=0.35
FOLDER_NAME=resultados_mct

# Ejemplo para PowerShell (Windows)
# $env:PHI="0.52"; $env:FOLDER_NAME="miercoles1"; docker compose up --build --force-recreate

# Ejemplo para bash (Linux/macOS)
# PHI=0.52 FOLDER_NAME=miercoles docker compose up --build --force-recreate
```

---

## ▶️ Cómo ejecutar la simulación

### Opción 1: usando `.env` (recomendado)

```bash
docker compose up --build --force-recreate
```

### Opción 2: desde la terminal

#### Linux / macOS
```bash
PHI=0.35 FOLDER_NAME=resultados_mct docker compose up --build --force-recreate
```

#### Windows PowerShell
```powershell
$env:PHI="0.35"; $env:FOLDER_NAME="resultados_mct"; docker compose up --build --force-recreate
```

---

## 📤 Resultados

Los resultados se guardan en:

- Carpeta local: `./output_local/<FOLDER_NAME>/`
- Volumen Docker: `volumen_scgle` → montado en `/data_output/<FOLDER_NAME>/`

Archivos generados:
- `Fskt_phi_<valor>.dat`: Datos de Fs(k, t) normalizado.
- `resumen_phi_<valor>.dat`: Parámetros usados.
- `Fskt_phi_<valor>.svg`: Gráfica de Fs(k, t).

---

## 🧰 Contenido de Código Fuente

<details><summary><code>scgle.jl</code></summary>

```julia
# Aquí va tu código SCGLE en Julia...
```
</details>

<details><summary><code>entrypoint.sh</code></summary>

```bash
#!/bin/bash
# Script de entrada
```
</details>

<details><summary><code>Dockerfile</code></summary>

```dockerfile
# Dockerfile base
```
</details>

<details><summary><code>docker-compose.yml</code></summary>

```yaml
services:
  scgle:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: dinamica_mct
    volumes:
      - ./:/workspace
      - ./output_local:/workspace/output
      - volumen_scgle:/data_output
    working_dir: /workspace
    environment:
      - PHI=${PHI}
      - FOLDER_NAME=${FOLDER_NAME}
    entrypoint: ["bash", "./entrypoint.sh"]

volumes:
  volumen_scgle:

# docker compose down --volumes
# docker system prune -a --volumes -f
```
</details>

---

📝 **Autor:** Víctor Guadalupe Rivera Juárez  
📅 **Fecha:** Junio 2025
