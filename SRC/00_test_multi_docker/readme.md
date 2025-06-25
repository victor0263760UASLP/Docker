
#  Proyecto: Simulación de Líquidos Simples con la Ecuación de Ornstein-Zernike

Este proyecto contiene todos los archivos necesarios para correr simulaciones de sistemas de esferas duras utilizando la ecuación de Ornstein-Zernike con el paquete `OrnsteinZernike.jl` en Julia. El entorno está encapsulado dentro de un contenedor Docker, lo que asegura portabilidad y reproducibilidad.

---

## 📁 Archivos Incluidos

| Archivo                | Descripción |
|------------------------|-------------|
| `OZE5.jl`              | Script de Julia que resuelve la ecuación de Ornstein-Zernike con cierre Percus-Yevick. |
| `entrypoint.sh`        | Script Bash que prepara el entorno y lanza el script Julia. |
| `Dockerfile`           | Imagen Docker que instala Julia, dependencias y configura el entorno. |
| `docker-compose.yml`   | Orquestador para construir y ejecutar el contenedor con parámetros definidos. |
| `.env`                 | Variables de entorno para controlar los parámetros físicos y nombre de carpetas. |

---

## Script Principal: `OZE5.jl`

Script en Julia que:

- Recibe parámetros desde la línea de comandos.
- Configura un sistema de partículas duras en 3D.
- Resuelve la ecuación de Ornstein-Zernike con cierre de Percus-Yevick.
- Guarda `g(r)` y los parámetros usados en archivos `.dat`.

Ejemplo de ejecución directa:

```bash
julia OZE5.jl 0.35 1.0 "./resultados_local" "./resultados_volumen"
```

---

##  `entrypoint.sh`

Script Bash que:

- Verifica variables de entorno: `PHI`, `KBT`, `FOLDER_NAME`.
- Crea carpetas de salida.
- Ejecuta `OZE5.jl` con los valores recibidos.

---

## `Dockerfile`

Construye una imagen basada en `julia:1.11` con:

- Herramientas del sistema necesarias (`curl`, `git`, `dos2unix`...).
- Clonación de `OrnsteinZernike.jl`.
- Instalación de dependencias Julia (`DelimitedFiles`, `JSON`).

---

##  `docker-compose.yml`

Permite ejecutar el contenedor fácilmente:

```bash
docker compose up --build --force-recreate
```

Usa variables de entorno para ajustar el sistema simulado y el nombre de la carpeta de salida.

---

##  `.env`

```env
PHI=0.35
KBT=1.0
FOLDER_NAME=resultados_oz
```

Estas variables controlan la fracción de empaque, la energía térmica y la carpeta de salida para los resultados.

---

##  Salidas esperadas

- `result_HS_phi_0_35.dat`: Función de correlación radial `g(r)`.
- `resumen_parametros_phi_0_35.dat`: Parámetros físicos usados.

Ubicación: tanto en la carpeta local (`/workspace/output`) como en volumen persistente (`/data_output`).

---

##  Ejemplo completo (Linux/macOS)

```bash
export PHI=0.35
export KBT=1.0
export FOLDER_NAME=resultados_oz
docker compose up --build --force-recreate
```

##  Ejemplo completo (Windows PowerShell)

```powershell
$env:PHI="0.35"; $env:KBT="1.0"; $env:FOLDER_NAME="resultados_oz"
docker compose up --build --force-recreate
```

---

##  Limpieza

```bash
docker compose down -v
```

---

##  Autoría y Créditos

Este proyecto utiliza el paquete [`OrnsteinZernike.jl`](https://github.com/IlianPihlajamaa/OrnsteinZernike.jl) desarrollado por Ilian Pihlajamaa.

---


---

##  Código Fuente de los Archivos

### `OZE5.jl`

```julia
using DelimitedFiles
using OrnsteinZernike

function save_data(nombre, formato; header = "", flag = true)
    @assert typeof(nombre) == String "El primer argumento debe ser texto"
    open(nombre, "w") do io
        if header != ""
            write(io, "# " * header * "\n")
        end
        writedlm(io, formato)
    end
    if flag
        println(" Data saved as ", nombre)
    end
end

function main(args...)
    if length(args) < 4
        @error "Se requieren 4 argumentos: PHI, KBT, local_folder, volume_folder"
        return
    end

    try
        φ = parse(Float64, args[1])
        kBT = parse(Float64, args[2])
        local_folder = args[3]
        volume_folder = args[4]

        println("Argumentos recibidos: ", args)

        mkpath(local_folder)
        mkpath(volume_folder)

        dims = 3
        σ = 1.0
        ϵ = 1.0
        ρ = (6 / π) * φ
        potential = HardSpheres(σ)
        closure = PercusYevick()
        system = SimpleLiquid(dims, ρ, kBT, potential)

        sol = solve(system, closure)

        datos = [sol.r sol.gr]
        filename = "result_HS_phi_$(replace(string(φ), "." => "_")).dat"

        save_data(joinpath(local_folder, filename), datos, header = "r g(r)")
        save_data(joinpath(volume_folder, filename), datos, header = "r g(r)")

        resumen = [
            ["tipo_potencial" "HardSpheres"];
            ["sigma" σ];
            ["phi" φ];
            ["rho" ρ];
            ["kBT" kBT];
            ["puntos" length(sol.r)]
        ]
        resumen_name = "resumen_parametros_phi_$(replace(string(φ), "." => "_")).dat"
        save_data(joinpath(local_folder, resumen_name), resumen, header = "Parámetro Valor")
        save_data(joinpath(volume_folder, resumen_name), resumen, header = "Parámetro Valor")

    catch error
        @error " Error resolviendo el sistema: $error"
    end
end

main(ARGS...)
```


### `entrypoint.sh`

```bash
#!/bin/bash
set -euo pipefail

# Verificar variables de entorno
if [ -z "${PHI:-}" ] || [ -z "${KBT:-}" ] || [ -z "${FOLDER_NAME:-}" ]; then
  echo "ERROR: Faltan variables de entorno requeridas."
  echo "Define PHI, KBT y FOLDER_NAME en el archivo .env o al ejecutar el contenedor."
  exit 1
fi

echo "PHI: $PHI"
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

# Verificar que Julia está instalada.
command -v julia >/dev/null 2>&1 || { echo >&2 "Julia no está instalada."; exit 1; }

julia OZE5.jl "$PHI" "$KBT" "$LOCAL_PATH" "$VOLUME_PATH"
```


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

COPY OZE5.jl /workspace/OZE5.jl
COPY entrypoint.sh /workspace/entrypoint.sh

RUN dos2unix /workspace/entrypoint.sh && chmod +x /workspace/entrypoint.sh

ENTRYPOINT ["bash", "/workspace/entrypoint.sh"]
```


### `docker-compose.yml`

```yaml
services:
  ornstein-zernike:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: multi_test
    volumes:
      - ./:/workspace
      - ./output_local:/workspace/output
      - volumen_lanimfe:/data_output
    working_dir: /workspace
    environment:
      - PHI=${PHI}
      - KBT=${KBT}
      - FOLDER_NAME=${FOLDER_NAME}
    entrypoint: ["bash", "./entrypoint.sh"]

volumes:
  volumen_lanimfe:
```


### `.env`

```env
PHI=0.35
KBT=1.0
FOLDER_NAME=resultados_oz
```

