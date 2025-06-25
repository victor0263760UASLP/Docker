# Resolución de la Ecuación de Ornstein-Zernike con Potencial Power-Law

Este proyecto usa Julia dentro de un contenedor Docker para resolver la ecuación de Ornstein-Zernike con un potencial tipo power-law utilizando la cerradura de Hypernetted Chain (HNC). El objetivo es generar datos `g(r)` en archivos `.dat` y guardar los parámetros físicos utilizados para cada compilación.

---

##  Archivos incluidos

- `power_dockerduo.jl`: script principal de Julia que realiza el cálculo físico.
- `entrypoint.sh`: script Bash que ejecuta Julia con variables del entorno.
- `Dockerfile`: imagen con Julia 1.11 y las dependencias requeridas.
- `docker-compose.yml`: orquesta el contenedor y volúmenes.
- `.env`: define parámetros físicos usados como entrada.

---

##  Cómo ejecutar

### Usando Docker Compose

#### En Linux o macOS

```bash
EPSILON=1.0 SIGMA=1.0 N=12 PHI=0.35 KBT=1.0 FOLDER_NAME=resultados_powerlaw \
docker compose up --build --force-recreate
```

#### En Windows PowerShell

```powershell
$env:EPSILON="1.0"
$env:SIGMA="1.0"
$env:N="12"
$env:PHI="0.35"
$env:KBT="1.0"
$env:FOLDER_NAME="resultados_powerlaw"
docker compose up --build --force-recreate
```

---

## Código fuente

### `power_dockerduo.jl`

```julia
using DelimitedFiles
using OrnsteinZernike

function save_data(nombre, formato; header = "", flag = true)
    @assert typeof(nombre) == typeof("hola") "El primer argumento debe ser texto"
    open(nombre, "w") do io
        if header != ""
            write(io, "# " * header * "\n")
        end
        writedlm(io, formato)
    end
    if flag println("Data saved as ", nombre) end
end

function main(args...)
    try
        ϵ = parse(Float64, args[1])
        σ = parse(Float64, args[2])
        n = parse(Int64, args[3])
        φ = parse(Float64, args[4])
        kBT = parse(Float64, args[5])
        local_folder = args[6]
        volume_folder = args[7]

        mkpath(local_folder)
        mkpath(volume_folder)

        potential = PowerLaw(ϵ, σ, n)
        dims = 3
        ρ = (6 / π) * φ
        system = SimpleLiquid(dims, ρ, kBT, potential)
        closure = HypernettedChain()
        sol = solve(system, closure)

        datos = [sol.r sol.gr]
        filename = "result_$(ϵ)_$(σ)_$(n)_$(φ)_$(kBT).dat"

        save_data(joinpath(local_folder, filename), datos, header = "r g(r)")
        save_data(joinpath(volume_folder, filename), datos, header = "r g(r)")

        resumen = [
            ["epsilon" ϵ];
            ["sigma" σ];
            ["n" n];
            ["phi" φ];
            ["rho" ρ];
            ["kBT" kBT];
            ["puntos" length(sol.r)]
        ]

        resumen_name = "resumen_parametros.dat"
        save_data(joinpath(local_folder, resumen_name), resumen, header = "Parámetro Valor")
        save_data(joinpath(volume_folder, resumen_name), resumen, header = "Parámetro Valor")

    catch error
        @error " Error resolviendo el sistema: $error"
    end
end

main(ARGS...)
```

---

### `entrypoint.sh`

```bash
#!/bin/bash
set -euo pipefail

if [[ -z "${EPSILON:-}" || -z "${SIGMA:-}" || -z "${N:-}" || -z "${PHI:-}" || -z "${KBT:-}" || -z "${FOLDER_NAME:-}" ]]; then
  echo "ERROR: Faltan variables de entorno requeridas."
  exit 1
fi

echo "EPSILON: $EPSILON"
echo "SIGMA: $SIGMA"
echo "N: $N"
echo "PHI: $PHI"
echo "KBT: $KBT"
echo "FOLDER_NAME: $FOLDER_NAME"

LOCAL_PATH="/workspace/$FOLDER_NAME"
VOLUME_PATH="/data_output/$FOLDER_NAME"

mkdir -p "$LOCAL_PATH"
mkdir -p "$VOLUME_PATH"

command -v julia >/dev/null 2>&1 || { echo >&2 "Julia no está instalada."; exit 1; }

julia power_dockerduo.jl "$EPSILON" "$SIGMA" "$N" "$PHI" "$KBT" "$LOCAL_PATH" "$VOLUME_PATH"
```

---

### `Dockerfile`

```dockerfile
FROM julia:1.11

RUN apt-get update && apt-get install -y \
    bash curl wget git build-essential libcurl4-openssl-dev ca-certificates dos2unix \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

RUN git clone https://github.com/IlianPihlajamaa/OrnsteinZernike.jl

RUN julia -e 'using Pkg; Pkg.add(PackageSpec(path="OrnsteinZernike.jl")); Pkg.instantiate()'
RUN julia -e 'using Pkg; Pkg.add("JSON"); Pkg.add("DelimitedFiles")'

COPY power_dockerduo.jl /workspace/power_dockerduo.jl
COPY entrypoint.sh /workspace/entrypoint.sh

RUN dos2unix /workspace/entrypoint.sh && chmod +x /workspace/entrypoint.sh

ENTRYPOINT ["bash", "/workspace/entrypoint.sh"]
```

---

### `docker-compose.yml`

```yaml
services:
  ornstein-zernike:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: power_law
    volumes:
      - ./:/workspace
      - ./output_local:/workspace/output
      - volumen_lanimfe:/data_output
    working_dir: /workspace
    environment:
      - EPSILON=${EPSILON}
      - SIGMA=${SIGMA}
      - N=${N}
      - PHI=${PHI}
      - KBT=${KBT}
      - FOLDER_NAME=${FOLDER_NAME}
    entrypoint: ["bash", "./entrypoint.sh"]

volumes:
  volumen_lanimfe:
```

---

### `.env`

```env
EPSILON=1.0
SIGMA=1.0
N=12
PHI=0.35
KBT=1.0
FOLDER_NAME=resultados_powerlaw
```

---

##  Salida esperada

- Archivos `.dat` en `output_local/<FOLDER_NAME>` y en el volumen Docker `volumen_lanimfe`.
- Incluyen:
  - `result_ϵ_σ_n_φ_kBT.dat` → datos `g(r)`
  - `resumen_parametros.dat` → parámetros del sistema

---

##  Requisitos

- Docker y Docker Compose instalados.
- No se necesita tener Julia localmente.

---

##  Licencia

Este proyecto esta restringuido solo con consentimiento del autor  Rivera Juárez Victor Guadalupe o asesores Ricardo Peredo Ortiz y Magdaleno Medina Noyola para propósitos educativos e investigación.
