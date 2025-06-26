#  Simulación de Líquidos con Potencial Yukawa en Julia usando Docker

Este proyecto permite simular líquidos simples en 3D con potencial Yukawa utilizando la ecuación de Ornstein-Zernike. Se ejecuta fácilmente usando Docker y Docker Compose en Windows, macOS y Linux.

---

##  Archivos del Proyecto

- `Rampa.jl`: Script principal en Julia que realiza la simulación.
- `entrypoint.sh`: Script Bash que valida variables, prepara carpetas y ejecuta el código de Julia.
- `Dockerfile`: Define la imagen de Docker con Julia, sus dependencias y el repositorio `OrnsteinZernike.jl`.
- `docker-compose.yml`: Orquesta la ejecución del contenedor y define volúmenes y variables.
- `.env`: Define los parámetros físicos y de ejecución. (Opcional)

---

##  Variables de Entorno

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

##  Cómo Ejecutar la Simulación

###  Requisitos previos

- Tener [Docker](https://www.docker.com/products/docker-desktop/) y [Docker Compose](https://docs.docker.com/compose/) instalados.

### Opción 1: Usando archivo `.env` (recomendado)

```bash
docker compose up --build --force-recreate
```

### Opción 2: Declarando variables en consola

####  En Linux/macOS

```bash
SIGMA=144.0 Z=-440.0 KBT=0.59 PHI=0.00081 M=10000 N_STAGES=50 MAX_ITER=10000 CHI_LIST="0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.95,0.99" FOLDER_NAME=Rampa docker compose up --build --force-recreate
```

####  En Windows (PowerShell)

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

##  Ejemplo de archivo `.env`

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

##  Resultados

Los resultados se guardan en:

- Carpeta local: `./output_local/Rampa/`
- Volumen de Docker: `volumen_lanimfe`

Por cada etapa se generan los siguientes archivos:

- `gdr_phi_<valor>_<idx>.dat`: función de distribución radial \( g(r) \)
- `sdk_phi_<valor>_<idx>.dat`: factor de estructura \( S(k) \)

---

##  Requisitos Técnicos

- Docker + Docker Compose
- Julia ≥ 1.11 (ya instalada dentro del contenedor Docker)
- Repositorio: [OrnsteinZernike.jl](https://github.com/IlianPihlajamaa/OrnsteinZernike.jl)

---
##  Contenido de Código Fuente

<details><summary><code>Rampa.jl</code></summary>

```julia
#Rivera Juarez Victor Guadalupe Rivera Juarez 9 de Junio del 2025

using OrnsteinZernike: PercusYevick, HypernettedChain, CustomPotential, SimpleLiquid, DensityRamp, NgIteration, solve
using DelimitedFiles

function save_data(nombre, formato; header = "", flag = true)
    @assert typeof(nombre) == typeof("hola") "El primer argumento debe ser texto"
    open(nombre, "w") do io
        if header != ""
            write(io, "# " * header * "\n")
        end
        writedlm(io, formato)
    end
if flag
    println("Data saved as ", nombre) end
end

function main(args...)
    if length(args) < 10
        @error "Se requieren 10 argumentos: σ z kBT φ M N_stages max_iter chi_list local_folder volume_folder"
        return
    end

    σ            = parse(Float64, args[1])
    z            = parse(Float64, args[2])
    kBT          = parse(Float64, args[3])
    φ            = parse(Float64, args[4])
    M            = parse(Int, args[5])
    N_stages     = parse(Int, args[6])
    max_iter     = parse(Int, args[7])
    chi_list_str = args[8]
    local_folder = args[9]
    volume_folder = args[10]
    

    mkpath(local_folder)  # Crea carpeta si no existe
    mkpath(volume_folder)

    χ = parse.(Float64, split(chi_list_str, ","))

    # Parámetros Yukawa
    κ = σ / 566.02
    p = (λB = 0.71432 / σ, σ = 1.0, κ = κ, z = -z)

    function Yukawa_R(r, p)
        κa = p.κ * 0.5 * p.σ
        LB = (p.z^2) * p.λB * exp(2 * κa) / (1 + κa)^2
        return LB * exp(-p.κ * r) / r
    end

    potential = CustomPotential(Yukawa_R, p)

    dims = 3
    ρ = (6 / π) * φ
    system = SimpleLiquid(dims, ρ, kBT, potential)
    closure = HypernettedChain()

    dr = 200.0 / M
    method = NgIteration(M = M; dr = dr, max_iterations = max_iter, N_stages = N_stages)
    densities = ρ .* χ
    method2 = DensityRamp(method, densities)

    SOL = solve(system, closure, method2)

    phi_str = replace(string(round(φ, digits=4)), "." => "p")

    for (idx, sol) in enumerate(SOL)
        gr_filename = joinpath(local_folder, "gdr_phi_" * phi_str * "_" * string(idx) * ".dat")
        save_data(gr_filename, hcat(sol.r, sol.gr), header = "r g(r)")

        sk_filename = joinpath(local_folder, "sdk_phi_" * phi_str * "_" * string(idx) * ".dat")
        save_data(sk_filename, hcat(sol.k, sol.Sk), header = "k S(k)")

        gr_filename = joinpath(volume_folder, "gdr_phi_" * phi_str * "_" * string(idx) * ".dat")
        save_data(gr_filename, hcat(sol.r, sol.gr), header = "r g(r)")

        sk_filename = joinpath(volume_folder, "sdk_phi_" * phi_str * "_" * string(idx) * ".dat")
        save_data(sk_filename, hcat(sol.k, sol.Sk), header = "k S(k)")
    end

end

    
main(ARGS...)




```
</details>

<details><summary><code>entrypoint.sh</code></summary>

```bash
#!/bin/bash
set -euo pipefail

# Verificar variables de entorno requeridas
if [ -z "${SIGMA:-}" ] || [ -z "${Z:-}" ] || [ -z "${KBT:-}" ] || [ -z "${PHI:-}" ] || [ -z "${M:-}" ] || [ -z "${N_STAGES:-}" ] || [ -z "${MAX_ITER:-}" ] || [ -z "${CHI_LIST:-}" ] || [ -z "${FOLDER_NAME:-}" ]; then
  echo "ERROR: Faltan variables de entorno requeridas."
  echo "Define SIGMA, Z, KBT, PHI, M, N_STAGES, MAX_ITER, CHI_LIST y FOLDER_NAME en el archivo .env o al ejecutar el contenedor."
  exit 1
fi

echo "PHI: $PHI"
echo "KBT: $KBT"
echo "SIGMA: $SIGMA"
echo "Z: $Z"
echo "M: $M"
echo "N_STAGES: $N_STAGES"
echo "MAX_ITER: $MAX_ITER"
echo "CHI_LIST: $CHI_LIST"
echo "FOLDER_NAME: $FOLDER_NAME"

LOCAL_PATH="/workspace/$FOLDER_NAME"
VOLUME_PATH="/data_output/$FOLDER_NAME"

mkdir -p "$LOCAL_PATH"
mkdir -p "$VOLUME_PATH"

echo "Local Path: $LOCAL_PATH"
echo "Volume Path: $VOLUME_PATH"
echo ""

command -v julia >/dev/null 2>&1 || { echo >&2 "Julia no está instalada."; exit 1; }

julia Rampa.jl "$SIGMA" "$Z" "$KBT" "$PHI" "$M" "$N_STAGES" "$MAX_ITER" "$CHI_LIST" "$LOCAL_PATH" "$VOLUME_PATH"





```
</details>

<details><summary><code>Dockerfile</code></summary>

```dockerfile
FROM julia:1.11

# Instalar dependencias del sistema y dos2unix
RUN apt-get update && apt-get install -y \
    bash curl wget git build-essential libcurl4-openssl-dev ca-certificates dos2unix \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Clonar el repositorio de Julia
RUN git clone https://github.com/IlianPihlajamaa/OrnsteinZernike.jl

# Instalar paquetes de Julia necesarios
RUN julia -e 'using Pkg; Pkg.add(PackageSpec(path="OrnsteinZernike.jl")); Pkg.instantiate()'
RUN julia -e 'using Pkg; Pkg.add("JSON"); Pkg.add("DelimitedFiles")'

# Copiar archivos locales (script y entrypoint)
COPY Rampa.jl /workspace/Rampa.jl
COPY entrypoint.sh /workspace/entrypoint.sh

# Asegurar que el script tenga formato UNIX y permisos de ejecución
RUN dos2unix /workspace/entrypoint.sh && chmod +x /workspace/entrypoint.sh

# Ejecutar entrypoint
ENTRYPOINT ["bash", "/workspace/entrypoint.sh"]


```
</details>

<details><summary><code>docker-compose.yml</code></summary>

```yaml
#version: "3.8"

services:
  ornstein-zernike:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: Rampa2
    volumes:
      - ./:/workspace
      - ./output_local:/workspace/output
      - volumen_lanimfe:/data_output
    working_dir: /workspace
    environment:
      - SIGMA
      - Z
      - KBT
      - PHI
      - M
      - N_STAGES
      - MAX_ITER
      - CHI_LIST
      - FOLDER_NAME
    entrypoint: ["bash", "./entrypoint.sh"]

volumes:
  volumen_lanimfe:

```
</details>

---

##  Autor

**Víctor Guadalupe Rivera Juárez**  
9 de Junio del 2025

