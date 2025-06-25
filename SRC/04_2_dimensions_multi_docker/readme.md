
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

##  Cómo usarlo

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

##  Ejemplos de ejecución avanzados

```bash
export DENSITIES=0.11,0.21,0.31,0.41,0.51,0.61,0.7
export DIMENSION=2
export KBT=1.0
export N_STAGES=10
export FOLDER_NAME=nuevo1
docker compose up --build --force-recreate
```

---

##  Resultados

Los resultados se guardan en:

- Carpeta local: `output_local/resultados_density/`
- Volumen Docker: `volumen_lanimfe`

---

##  `docker-compose.yml`

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

##  `Dockerfile`

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

##  `entrypoint.sh`

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



## Script Julia (`density.jl`)
```Julia
using DelimitedFiles
using OrnsteinZernike

function save_data(nombre, formato; header = "", flag = true)
    @assert typeof(nombre) == String ""
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
    if length(args) < 5
        @error "Se requieren 5 argumentos: densities_csv, dimension, kBT, local_folder, volume_folder"
        return
    end

    try
        densities_csv = args[1]
        dimension = parse(Int, args[2])
        kBT = parse(Float64, args[3])
        local_folder = args[4]
        volume_folder = args[5]

        densities = parse.(Float64, split(densities_csv, ","))

        mkpath(local_folder)
        mkpath(volume_folder)

        potential = HardSpheres(1.0)

        puntos = 0  

        for density in densities
            println("Resolviendo para densidad = $density")

            try
                system = SimpleLiquid(dimension, density, kBT, potential)
                closure = PercusYevick()
                sol = solve(system, closure)

                filename = "result_density_$(replace(string(density), "." => "_")).dat"
                header = "r g(r)"
                data = [sol.r sol.gr]

                save_data(joinpath(local_folder, filename), data, header=header)
                save_data(joinpath(volume_folder, filename), data, header=header)

                puntos = length(sol.r) 

            catch inner_error
                @error "Error resolviendo sistema para densidad $density: $inner_error"
            end
        end

        if puntos > 0
            resumen = [
                ["densities" densities_csv];
                ["dimension" dimension];
                ["kBT" kBT];
                ["puntos" puntos]
            ]

            resumen_name = "resumen_parametros.dat"
            save_data(joinpath(local_folder, resumen_name), resumen, header="Parámetro Valor")
            save_data(joinpath(volume_folder, resumen_name), resumen, header="Parámetro Valor")
        else
            @warn "No se pudo resolver ninguna densidad. No se generó resumen."
        end

    catch error
        @error "Error general resolviendo el sistema: $error"
    end
end

main(ARGS...)
```
```bash
#export DENSITIES=0.11,0.21,0.31,0.41,0.51,0.61,0.7;export DIMENSION=2; export KBT=1.0;  export N_STAGES=10; export FOLDER_NAME=nuevo1; docker compose up --build --force-
#$env:DENSITIES="0.11,0.21,0.31,0.41,0.51,0.61,0.7"; $env:DIMENSION="2"; $env:KBT="1.0"; $env:N_STAGES="10"; $env:FOLDER_NAME="dimensions"; docker compose up --build --force-recreate
#DENSITIES="0.11,0.21,0.31,0.41,0.51,0.61,0.7"; DIMENSION="2"; KBT="1.0"; N_STAGES="10"; FOLDER_NAME="dimensions"; docker compose up --build --force-recreate
#mac_1DENSITIES="0.11,0.21,0.31,0.41,0.51,0.61,0.7" \DIMENSION="2" \KBT="1.0" \N_STAGES="10" \FOLDER_NAME="dimensions" \docker compose up --build --force-recreate
```
