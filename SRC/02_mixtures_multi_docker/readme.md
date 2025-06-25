# Simulación de Mezclas Binarias de Esferas Duras usando Docker y Julia

Este repositorio permite ejecutar simulaciones de una mezcla binaria de esferas duras en 3D utilizando la ecuación de Ornstein-Zernike con el cierre de Percus-Yevick, mediante un contenedor Docker que automatiza todo el proceso.

---

## Contenido del Proyecto

### 1. `mixtures.jl`
Script principal en Julia que:
- Define un sistema de partículas duras (diámetros `D1`, `D2`).
- Usa el cierre de Percus-Yevick.
- Resuelve la ecuación OZ para obtener funciones de correlación radial `g_ij(r)`.
- Guarda los resultados en carpetas locales y de volumen.

```julia
using DelimitedFiles
using OrnsteinZernike

function save_data(nombre, formato; header = "", flag = true)
    @assert typeof(nombre) == String "El primer argumento debe ser texto"
    open(nombre, "w") do io
        if header != ""
            write(io, "# " * header * "
")
        end
        writedlm(io, formato)
    end
    if flag
        println("Data saved as ", nombre)
    end
end

function main(args...)
    if length(args) < 5
        @error "Se requieren 5 argumentos: D1, D2, rho_total, kBT, local_folder, volume_folder"
        return
    end

    try
        D1 = parse(Float64, args[1])
        D2 = parse(Float64, args[2])
        rho_total = parse(Float64, args[3])
        kBT = parse(Float64, args[4])
        local_folder = args[5]
        volume_folder = args[6]

        mkpath(local_folder)
        mkpath(volume_folder)

        D = [D1, D2]
        potential = HardSpheres(D)
        dims = 3
        ρ = rho_total * [0.5, 0.5] 
        system = SimpleLiquid(dims, ρ, kBT, potential)

        closure = PercusYevick()

        sol = solve(system, closure)

        datos = [sol.r sol.gr[:, 1, 1] sol.gr[:, 1, 2] sol.gr[:, 2, 1] sol.gr[:, 2, 2]]
        filename = "result_mixture_$(D1)_$(D2)_$(rho_total)_$(kBT).dat"

        header = "r g_11 g_12 g_21 g_22"
        save_data(joinpath(local_folder, filename), datos, header=header)
        save_data(joinpath(volume_folder, filename), datos, header=header)

        resumen = [
            ["D1" D1];
            ["D2" D2];
            ["rho_total" rho_total];
            ["rho_1" ρ[1]];
            ["rho_2" ρ[2]];
            ["kBT" kBT];
            ["puntos" length(sol.r)]
        ]
        resumen_name = "resumen_parametros.dat"
        save_data(joinpath(local_folder, resumen_name), resumen, header="Parámetro Valor")
        save_data(joinpath(volume_folder, resumen_name), resumen, header="Parámetro Valor")

    catch error
        @error "Error resolviendo el sistema: $error"
    end
end

main(ARGS...)
```

---

### 2. `entrypoint.sh`
Script de entrada que:
- Verifica las variables de entorno necesarias.
- Crea carpetas locales y de volumen.
- Ejecuta `mixtures.jl` con los argumentos adecuados.

```bash
#!/bin/bash
set -euo pipefail

if [ -z "${D1:-}" ] || [ -z "${D2:-}" ] || [ -z "${RHO_TOTAL:-}" ] || [ -z "${KBT:-}" ] || [ -z "${FOLDER_NAME:-}" ]; then
  echo "ERROR: Faltan variables de entorno requeridas."
  echo "Define D1, D2, RHO_TOTAL, KBT y FOLDER_NAME en el archivo .env o al ejecutar el contenedor."
  exit 1
fi

echo "D1: $D1"
echo "D2: $D2"
echo "RHO_TOTAL: $RHO_TOTAL"
echo "KBT: $KBT"
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

julia mixtures.jl "$D1" "$D2" "$RHO_TOTAL" "$KBT" "$LOCAL_PATH" "$VOLUME_PATH"
```

---

### 3. `Dockerfile`
Define una imagen Docker basada en Julia 1.11 con:
- Dependencias del sistema.
- Paquete `OrnsteinZernike.jl` clonado e instalado.
- El script `mixtures.jl` y `entrypoint.sh` copiados y ejecutables.

```Dockerfile
FROM julia:1.11

RUN apt-get update && apt-get install -y     bash curl wget git build-essential libcurl4-openssl-dev ca-certificates dos2unix     && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

RUN git clone https://github.com/IlianPihlajamaa/OrnsteinZernike.jl

RUN julia -e 'using Pkg; Pkg.add(PackageSpec(path="OrnsteinZernike.jl")); Pkg.instantiate()'
RUN julia -e 'using Pkg; Pkg.add("JSON"); Pkg.add("DelimitedFiles")'

COPY mixtures.jl /workspace/power_dockerduo.jl
COPY entrypoint.sh /workspace/entrypoint.sh

RUN dos2unix /workspace/entrypoint.sh && chmod +x /workspace/entrypoint.sh

ENTRYPOINT ["bash", "/workspace/entrypoint.sh"]
```

---

### 4. `docker-compose.yml`
Orquesta todo el entorno:
- Construye la imagen.
- Define variables desde `.env`.
- Monta volúmenes.
- Ejecuta el `entrypoint.sh`.

```yaml
services:
  ornstein-zernike:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: mixtures
    volumes:
      - ./:/workspace
      - ./output_local:/workspace/output
      - volumen_lanimfe:/data_output
    working_dir: /workspace
    environment:
      - D1=${D1}
      - D2=${D2}
      - RHO_TOTAL=${RHO_TOTAL}
      - KBT=${KBT}
      - FOLDER_NAME=${FOLDER_NAME}
    entrypoint: ["bash", "./entrypoint.sh"]

volumes:
  volumen_lanimfe:
```

---

### 5. `.env`
Define los valores de entrada usados por `entrypoint.sh`:

```env
D1=0.5
D2=1.0
RHO_TOTAL=1.6
KBT=1.0
FOLDER_NAME=resultados_mezclas
```

Opcionalmente puedes usar estos comandos directamente:
```bash
# PowerShell (Windows):
$env:D1="0.5"; $env:D2="1.0"; $env:RHO_TOTAL="1.6"; $env:KBT="1.0"; $env:FOLDER_NAME="resultados_mezclas"; docker compose up --build --force-recreate

# macOS/Linux:
D1=0.5 D2=1.0 RHO_TOTAL=1.6 KBT=1.0 FOLDER_NAME=resultados_mezclas docker compose up --build --force-recreate
```

---

## ⚡ Instrucciones de uso

1. Asegúrate de tener Docker y Docker Compose instalados.
2. Coloca todos los archivos en el mismo directorio.
3. Crea la carpeta `output_local` si no existe:
```bash
mkdir -p output_local
```
4. Ejecuta:
```bash
docker compose up --build --force-recreate
```

Los resultados se guardarán en:
- `output_local/resultados_mezclas/`
- El volumen `volumen_lanimfe` (persistente dentro de Docker)

