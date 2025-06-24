# Ornstein-Zernike con Volumen Docker

Este proyecto resuelve la ecuación de Ornstein-Zernike (OZ) con cerradura de Percus-Yevick para un sistema de esferas duras en 3D, utilizando contenedores Docker y montando un volumen llamado `volumen_oz`, el cual almacena los resultados en la carpeta `/workspace/carpeta`.

---

## Estructura del proyecto

```
├── Dockerfile              # Define la imagen de Julia con dependencias
├── entrypoint.sh           # Script de entrada que ejecuta el cálculo
├── OZE2_HS.jl              # Script Julia que resuelve la ecuación de OZ
├── docker-compose.yml      # Orquestación con Docker Compose
└── volumen (volumen_oz)    # Volumen de Docker que almacena resultados
```

---

## Archivos explicados

### `OZE2_HS.jl`
- Script en Julia que:
  - Define el sistema de esferas duras.
  - Resuelve la ecuación de Ornstein-Zernike.
  - Imprime resultados en formato JSON.

### `entrypoint.sh`
- Script bash que:
  - Crea un directorio de salida (`/workspace/carpeta`).
  - Ejecuta `OZE2_HS.jl` pasando un valor de `phi`.
  - Guarda los resultados en `result_$PARAM.dat`.

### `Dockerfile`
- Usa `julia:1.10` como imagen base.
- Instala:
  - Dependencias del sistema.
  - El paquete `OrnsteinZernike.jl` desde GitHub.
  - `JSON.jl`.
- Copia los scripts y configura el entorno.

### `docker-compose.yml`
- Orquesta todo con Docker Compose.
- Permite pasar un valor de `phi` como variable de entorno `PARAM`.
- Monta el volumen llamado `volumen_oz` en `/workspace/carpeta`.

---

## Requisitos

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- En Windows, asegúrate de tener [Docker Desktop](https://www.docker.com/products/docker-desktop/) funcionando correctamente.

---

## Cómo ejecutar

### 1. Clonar el repositorio 

```bash
git clone <https://github.com/tu_usuario/tu_repositorio>
cd <nombre_del_directorio>
```

### 2. Establecer el valor de `phi`

En Windows PowerShell:

```powershell
$env:PARAM="0.3"; docker-compose up --build
```

En Linux/Mac:

```bash
PARAM=0.3 docker-compose up --build
```

> Si no defines `PARAM`, el valor por defecto es `0.1`.

---

## Salida

- Los resultados se guardan automáticamente en el volumen Docker montado como:
  `./volumen_oz/result_<phi>.dat`
- También se imprimen en consola en formato JSON.

---

## Notas

- El contenedor se detiene al finalizar el cálculo.
- Puedes modificar `OZE2_HS.jl` para agregar visualizaciones o análisis adicionales.
- El nombre de la carpeta de salida es fijo: `carpeta`.

---

## Licencia

Este proyecto es solo para fines educativos o de investigación. Puedes modificarlo libremente para adaptarlo a tus necesidades.

---

## Código fuente relevante

### `OZE2_HS.jl`

```julia
using OrnsteinZernike
using JSON

function main(args...)
    phi_str = args[1][1]
    phi = parse(Float64, phi_str)

    dims = 3
    kBT = 1.0
    ρ = (6/pi) * phi
    potential = HardSpheres(1.0)
    system = SimpleLiquid(dims, ρ, kBT, potential)

    closure = PercusYevick()
    sol = @time solve(system, closure)

    params = Dict("phi" => phi)
    system = Dict("ID" => "HS", "params" => params)
    output = Dict("system" => system, "OZE" => sol)

    println(JSON.json(output))
end

main(ARGS)
```

### `entrypoint.sh`

```bash
#!/bin/bash
OUTPUT_DIR="/workspace/carpeta"
mkdir -p "$OUTPUT_DIR"
julia OZE2_HS.jl "$PARAM" > "$OUTPUT_DIR/result_$PARAM.dat"
```

### `Dockerfile`

```Dockerfile
FROM julia:1.10

RUN apt-get update && apt-get install -y \
    bash curl wget git build-essential \
    libcurl4-openssl-dev ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

RUN git clone https://github.com/IlianPihlajamaa/OrnsteinZernike.jl

RUN julia -e 'using Pkg; Pkg.add(PackageSpec(path="/workspace/OrnsteinZernike.jl")); Pkg.instantiate()'
RUN julia -e 'using Pkg; Pkg.add("JSON")'

ENV OUTPUT_DIR="/workspace/carpeta"
RUN mkdir -p $OUTPUT_DIR

COPY OZE2_HS.jl .
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

ENV PARAM=0.1
ENTRYPOINT ["bash", "./entrypoint.sh"]
```

### `docker-compose.yml`

```yaml
services:
  ornstein-zernike:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: crear_volumen
    environment:
      - PARAM=${PARAM:-0.1}
    volumes:
      - volumen_oz:/workspace/carpeta
    working_dir: /workspace
    entrypoint: ["./entrypoint.sh"]

volumes:
  volumen_oz:
```
