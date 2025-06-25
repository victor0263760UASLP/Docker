
#  Simulación de Líquidos con Potencial WCA (Lennard-Jones Truncado) en Julia usando Docker

Este proyecto permite simular líquidos simples en 2D usando la ecuación de Ornstein-Zernike con un potencial tipo WCA (Weeks-Chandler-Andersen). Está diseñado para ejecutarse fácilmente mediante Docker.

---

##  Archivos principales

- `WCA.jl`: Script en Julia que realiza la simulación.
- `entrypoint.sh`: Script Bash que prepara la ejecución.
- `Dockerfile`: Define el entorno de Julia y sus dependencias.
- `docker-compose.yml`: Orquesta la ejecución del contenedor.
- `.env`: Define los parámetros físicos de la simulación.

---

##  Variables de entorno

Estas se pueden declarar en un archivo `.env` o directamente en consola.

### Ejemplo de archivo `.env`

```env
PHI=0.5
KBT=1.0
SIGMA=1.0
EPSILON=1.8
FOLDER_NAME=carpeta_dios_gracias17
CLOSURE=PercusYevick
```

---

##  Cómo ejecutar la simulación

**Opción 1: Linux / macOS**

```bash
PHI=0.5 KBT=1.0 SIGMA=1.0 EPSILON=1.8 FOLDER_NAME=carpeta_dios_gracias17 CLOSURE=PercusYevick docker compose up --build --force-recreate
```

**Opción 2: Windows PowerShell**

```powershell
$env:PHI="0.4"; $env:KBT="1.0"; $env:SIGMA="1.0"; $env:EPSILON="1.8"; $env:FOLDER_NAME="sabado_nuevo"; $env:CLOSURE="HNC"; docker compose up --build --force-recreate
```

---

##  Resultados

Los resultados se guardan en:

- Carpeta local: `output_local/carpeta_dios_gracias17/`
- Volumen Docker: `volumen_WCA`

Archivos generados:

- `gdr_phi_<valor>.dat`: función de distribución radial \( g(r) \)
- `sdk_phi_<valor>.dat`: factor de estructura \( S(k) \)

---

##  Requisitos

- Docker + Docker Compose
- Julia >= 1.6 dentro del contenedor
- Repositorio: `OrnsteinZernike.jl`

---

##  Tipos de cerradura soportados

- `py` o `PercusYevick`
- `hnc` o `HypernettedChain`

Este entorno es útil para estudios de estructura de líquidos simples en condiciones controladas mediante simulación teórica.
##  Contenido de Código Fuente

<details><summary><code>wca.jl</code></summary>

```julia
using OrnsteinZernike: PercusYevick, HypernettedChain, CustomPotential, SimpleLiquid, NgIteration, solve

using DelimitedFiles

function save_data(nombre, formato; header = "", flag = true)
    open(nombre, "w") do io
        if header != ""
            write(io, "# " * header * "\n")
        end
        writedlm(io, formato)
    end
    if flag
        println("Data saved as ", nombre)
    end
end

function get_closure(closure_str)
    closure_str = lowercase(strip(closure_str))
    closure_map = Dict(
        "percusyevick" => PercusYevick(),
        "py"           => PercusYevick(),
        "HypernettedChain" => HypernettedChain(),
        "hnc"              => HypernettedChain()
    )
    if haskey(closure_map, closure_str)
        return closure_map[closure_str]
    else
        error("Cerradura no reconocida: '$closure_str'")
    end
end

function LJT(r, p)
    σ = p.σ
    return r <= (2^(1/6))*σ ? 4.0*p.ϵ * ((σ/r)^12 - (σ/r)^6) + p.ϵ : 0.0
end

function main(args...)
    if length(args) < 6
        @error "Se requieren 6 argumentos: ϕ kBT σ ϵ local_folder closure_str"
        return
    end

    ϕ = parse(Float64, args[1])
    kBT = parse(Float64, args[2])
    σ = parse(Float64, args[3])
    ϵ = parse(Float64, args[4])
    local_folder = args[5]
    closure_str = args[6]

    println("DEBUG: closure_str raw = '$closure_str'")
    closure_str = lowercase(strip(closure_str))
    println("DEBUG: closure_str cleaned = '$closure_str'")

    mkpath(local_folder)

    p = (σ = σ, ϵ = ϵ)
    potential = CustomPotential(LJT, p)

    dims = 2
    ρ = (4/π)*ϕ

    system = SimpleLiquid(dims, ρ, kBT, potential)
    closure = get_closure(closure_str)
    method = NgIteration()

    sol = solve(system, closure, method)

    phi_str = replace(string(round(ϕ, digits=4)), "." => "p")

    save_data(joinpath(local_folder, "gdr_phi_"*phi_str*".dat"),
              hcat(sol.r, sol.gr), header="r g(r)")
    save_data(joinpath(local_folder, "sdk_phi_"*phi_str*".dat"),
              hcat(sol.k, sol.Sk), header="k S(k)")
end

main(ARGS...)






```
</details>

<details><summary><code>entrypoint.sh</code></summary>

```bash

#!/bin/bash
set -euo pipefail

# Verificar variables de entorno
if [ -z "${PHI:-}" ] || [ -z "${KBT:-}" ] || [ -z "${SIGMA:-}" ] || [ -z "${EPSILON:-}" ] || [ -z "${FOLDER_NAME:-}" ] || [ -z "${CLOSURE:-}" ]; then
  echo "ERROR: Faltan variables de entorno requeridas."
  echo "Define PHI, KBT, SIGMA, EPSILON, FOLDER_NAME y CLOSURE en el archivo .env o al ejecutar el contenedor."
  exit 1
fi

echo "PHI: $PHI"
echo "KBT: $KBT"
echo "SIGMA: $SIGMA"
echo "EPSILON: $EPSILON"
echo "FOLDER_NAME: $FOLDER_NAME"
echo "CLOSURE: $CLOSURE"

LOCAL_PATH="/workspace/$FOLDER_NAME"
VOLUME_PATH="/data_output/$FOLDER_NAME"

mkdir -p "$LOCAL_PATH"
mkdir -p "$VOLUME_PATH"

echo "Local Path: $LOCAL_PATH"
echo "Volume Path: $VOLUME_PATH"
echo ""

command -v julia >/dev/null 2>&1 || { echo >&2 "Julia no está instalada."; exit 1; }

julia WCA.jl "$PHI" "$KBT" "$SIGMA" "$EPSILON" "$LOCAL_PATH" "$CLOSURE"




```
</details>

<details><summary><code>Dockerfile</code></summary>

```dockerfile
FROM julia:1.11

RUN apt-get update && apt-get install -y \
    bash curl wget git build-essential libcurl4-openssl-dev ca-certificates dos2unix \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Clonar OrnsteinZernike.jl
RUN git clone https://github.com/IlianPihlajamaa/OrnsteinZernike.jl

RUN julia -e 'using Pkg; Pkg.add(PackageSpec(path="OrnsteinZernike.jl")); Pkg.instantiate()'
RUN julia -e 'using Pkg; Pkg.add("DelimitedFiles")'

COPY WCA.jl /workspace/WCA.jl
COPY entrypoint.sh /workspace/entrypoint.sh

RUN dos2unix /workspace/entrypoint.sh && chmod +x /workspace/entrypoint.sh

ENTRYPOINT ["bash", "/workspace/entrypoint.sh"]




```
</details>

<details><summary><code>docker-compose.yml</code></summary>

```yaml
ersion: '3.9'

services:
  wca_container:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: wca_container_custom
    volumes:
      - ./:/workspace
      - ./output_local:/workspace/output
      - volumen_WCA:/data_output
    working_dir: /workspace
    environment:
      - PHI=${PHI}
      - KBT=${KBT}
      - SIGMA=${SIGMA}
      - EPSILON=${EPSILON}
      - FOLDER_NAME=${FOLDER_NAME}
      - CLOSURE=${CLOSURE}
    entrypoint: ["bash", "./entrypoint.sh"]

volumes:
  volumen_WCA:





```
</details>

---




