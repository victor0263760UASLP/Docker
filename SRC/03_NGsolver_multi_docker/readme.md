# Simulación de Factor Estructural \( S(k) \) para Esferas Duras con Docker y Julia

Este repositorio contiene los archivos y configuración necesarios para correr una simulación del factor estructural \( S(k) \) para un sistema de esferas duras usando el paquete OrnsteinZernike.jl dentro de un contenedor Docker.

---

## Contenido del proyecto

### 1. `3NG_Solver.jl`

Script en Julia que:

- Recibe parámetros: fracción de empaque \(\phi\), temperatura \(k_B T\), número de puntos \(M\), etapas del método Ng, y rutas de salida.
- Define el sistema de partículas duras con el cierre Percus-Yevick.
- Resuelve la ecuación de Ornstein-Zernike con aceleración Ng.
- Guarda el resultado \( S(k) \) y un resumen de parámetros.

```julia
using OrnsteinZernike
using DelimitedFiles

function save_data(nombre, formato; header = "", flag = true)
    @assert typeof(nombre) == String "El primer argumento debe ser texto"
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

function main(args...)
    try
        φ = parse(Float64, args[1])
        kBT = parse(Float64, args[2])
        M = parse(Int, args[3])
        N_stages = parse(Int, args[4])
        local_folder = args[5]
        volume_folder = args[6]

        mkpath(local_folder)
        mkpath(volume_folder)

        max_iter = 10000
        dr = 100.0 / M
        ρ = (6 / π) * φ

        potential = HardSpheres(1.0)
        dims = 3
        system = SimpleLiquid(dims, ρ, kBT, potential)
        closure = PercusYevick()
        method = NgIteration(M=M; dr=dr, max_iterations=max_iter, N_stages=N_stages)

        sol = solve(system, closure, method)

        filename = "Sk_phi$(φ)_kBT$(kBT)_M$(M)_N$(N_stages).dat"
        header = "k S(k)"
        data = hcat(sol.k, sol.Sk)

        save_data(joinpath(local_folder, filename), data; header=header)
        save_data(joinpath(volume_folder, filename), data; header=header)

        resumen = [
            ["phi" φ];
            ["kBT" kBT];
            ["M" M];
            ["N_stages" N_stages];
            ["rho" ρ];
            ["dr" dr];
            ["puntos_k" length(sol.k)]
        ]

        resumen_name = "resumen_parametros.dat"
        save_data(joinpath(local_folder, resumen_name), resumen, header="Parámetro Valor")
        save_data(joinpath(volume_folder, resumen_name), resumen, header="Parámetro Valor")

    catch error
        @error " Error resolviendo el sistema: $error"
    end
end

main(ARGS...)
```

---

### 2. `.env`

Archivo que define las variables de entorno para configurar la simulación.

```env
PHI=0.23
KBT=2.0
M=500
N_STAGES=10
FOLDER_NAME=resultados_oz
```

---

### 3. `docker-compose.yml`

Define el servicio para levantar el contenedor con la configuración necesaria.

```yaml
services:
  ornstein-zernike:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: ng_STAGES
    volumes:
      - ./:/workspace
      - ./output_local:/workspace/output
      - volumen_lanimfe:/data_output
    working_dir: /workspace
    environment:
      - PHI=${PHI}
      - KBT=${KBT}
      - M=${M}
      - N_STAGES=${N_STAGES}
      - FOLDER_NAME=${FOLDER_NAME}
    entrypoint: ["bash", "./entrypoint.sh"]

volumes:
  volumen_lanimfe:
```

---

### 4. `Dockerfile`

Construye la imagen Docker con Julia y las dependencias necesarias.

```dockerfile
FROM julia:1.11

RUN apt-get update && apt-get install -y \
    bash curl wget git build-essential libcurl4-openssl-dev ca-certificates dos2unix \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

RUN git clone https://github.com/IlianPihlajamaa/OrnsteinZernike.jl

RUN julia -e 'using Pkg; Pkg.add(PackageSpec(path="OrnsteinZernike.jl")); Pkg.instantiate()'
RUN julia -e 'using Pkg; Pkg.add("JSON"); Pkg.add("DelimitedFiles")'

COPY 3NG_Solver.jl /workspace/power_dockerduo.jl
COPY entrypoint.sh /workspace/entrypoint.sh

RUN dos2unix /workspace/entrypoint.sh && chmod +x /workspace/entrypoint.sh

ENTRYPOINT ["bash", "/workspace/entrypoint.sh"]
```

---

### 5. `entrypoint.sh`

Script de entrada que valida variables y ejecuta el script Julia.

```bash
#!/bin/bash
set -euo pipefail

if [ -z "${PHI:-}" ] || [ -z "${KBT:-}" ] || [ -z "${M:-}" ] || [ -z "${N_STAGES:-}" ] || [ -z "${FOLDER_NAME:-}" ]; then
  echo "ERROR: Faltan variables de entorno requeridas."
  echo "Define PHI, KBT, M, N_STAGES y FOLDER_NAME en el archivo .env o al ejecutar el contenedor."
  exit 1
fi

echo "PHI: $PHI"
echo "KBT: $KBT"
echo "M: $M"
echo "N_STAGES: $N_STAGES"
echo "FOLDER_NAME: $FOLDER_NAME"
echo ""

LOCAL_PATH="/workspace/$FOLDER_NAME"
VOLUME_PATH="/data_output/$FOLDER_NAME"

mkdir -p "$LOCAL_PATH"
mkdir -p "$VOLUME_PATH"

echo "Local Path: $LOCAL_PATH"
echo "Volume Path: $VOLUME_PATH"
echo ""

command -v julia >/dev/null 2>&1 || { echo >&2 "Julia no está instalada."; exit 1; }

julia 3NG_Solver.jl "$PHI" "$KBT" "$M" "$N_STAGES" "$LOCAL_PATH" "$VOLUME_PATH"
```

---

## Cómo usarlo

1. Instala [Docker](https://docs.docker.com/get-docker/) y Docker Compose.

2. Coloca todos los archivos juntos en un directorio.

3. Opcional: creamos una carpeta local para resultados para guardar datos .dat con este comando, se encuentra automátizado y listo para usar:
   ```bash
   mkdir -p output_local
   ```

4. Ejecuta Docker Compose definiendo las variables de entorno según tu sistema:

- **Linux / macOS (bash/zsh):**

  ```bash
  PHI=0.23 KBT=2.0 M=500 N_STAGES=10 FOLDER_NAME=resultados_oz docker compose up --build --force-recreate
  ```

- **Windows PowerShell:**

  ```powershell
  $env:PHI="0.23"; $env:KBT="2.0"; $env:M="500"; $env:N_STAGES="10"; $env:FOLDER_NAME="resultados_oz"; docker compose up --build --force-recreate
  ```

- **Windows CMD:**

  ```cmd
  set PHI=0.23&& set KBT=2.0&& set M=500&& set N_STAGES=10&& set FOLDER_NAME=resultados_oz&& docker compose up --build --force-recreate
  ```

5. Los resultados se guardan en:

   - Carpeta local: `output_local/resultados_oz/`
   - Volumen Docker: `volumen_lanimfe`

