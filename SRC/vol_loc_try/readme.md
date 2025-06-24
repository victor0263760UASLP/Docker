
 # Ornstein-Zernike para Esferas Duras con Docker Compose

Este proyecto resuelve la ecuación de Ornstein-Zernike (OZ) con cerradura de Percus-Yevick para un sistema de esferas duras en 3D, usando un contenedor Docker con Julia, pero no genera un volumen en la aplicación de docker Desktop,solo hace una carpeta con los archivos  localmente y para cambiarle el nombre a la carpeta debes ingresar  al entrypoint, donde dice particulas1 y cambiarlo.

---

## Estructura del proyecto

```
├── Dockerfile              # Define la imagen de Julia con dependencias
├── entrypoint.sh           # Script de entrada que ejecuta el cálculo
├── OZE2_HS.jl              # Script Julia que resuelve la ecuación de OZ
├── docker-compose.yml      # Orquestación con Docker Compose
└── workspace/
    └── particulas1/        # (Se crea automáticamente) Almacena resultados
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
  - Crea un directorio de salida (`/workspace/particulas1`).
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
- Permite pasar un valor de `phi` a través de una variable de entorno `PARAM`.
- Monta el volumen local en `/workspace`.

---

## Requisitos

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- En Windows, asegúrate de tener [Docker Desktop](https://www.docker.com/products/docker-desktop/) funcionando correctamente.

---

## Cómo ejecutar

### 1. Clonar el repositorio 

```bash
git clone <https://github.com/victor0263760UASLP/Docker/tree/main>
cd <Docker>
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

> Si no se define `PARAM`, se usará el valor por defecto `0.1`.

---

## Salida

- Los resultados se guardan en el directorio:  
  `./workspace/particulas1/result_<phi>.dat`

- También puedes verlos directamente en consola en formato JSON.

---

## Notas

- El contenedor se detiene una vez completado el cálculo.
- Puedes editar `OZE2_HS.jl` para agregar más análisis o salida gráfica si lo deseas.

---

## Licencia

Este proyecto es solo para fines educativos o de investigación. Adapta los archivos según tus necesidades.


---

## Código fuente

### `OZE2_HS.jl`

```julia
using OrnsteinZernike  # Carga la biblioteca para las soluciones de Ornstein-Zernike
using JSON              # Carga para usar formato  JSON

function main(args...)
    try
        # user inputs
        phi_str = args[1][1]
        phi = parse(Float64, phi_str)

        # Sistema de esferas duras
        dims = 3
        kBT = 1.0
        ρ = (6/pi) * phi
        potential = HardSpheres(1.0)
        system = SimpleLiquid(dims, ρ, kBT, potential)

        # Closure es la cerradura para la ecuación de Ornstein-Zernike
        closure = PercusYevick()

        # Resuelve el sistema utilizando la ecuación de Ornstein-Zernike
        sol = @time solve(system, closure)

        # Los parámetros dependientes de phi
        params = Dict("phi" => phi)  
        system = Dict("ID" => "HS", "params" => params)

        # Procesa y guarda los resultados
        data = Dict("system_solution" => sol)

        # Diccionario con la ecuación de OZE
        output = Dict("system" => system, "OZE" => sol)

        # Imprime la solución en formato JSON
        output = JSON.json(output)
        println(output)

    catch 
        return 500
    end
end

main(ARGS)
```


### `entrypoint.sh`

```bash
#!/bin/bash
# Directorio de salida
OUTPUT_DIR="/workspace/particulas1"

# Asegurarse de que el directorio existe
mkdir -p "$OUTPUT_DIR"

# Ejecutar el script de Julia y guardar la salida en un archivo
julia OZE2_HS.jl "$PARAM" > "$OUTPUT_DIR/result_$PARAM.dat"
```


### `Dockerfile`

```Dockerfile
# Usamos la imagen oficial de Julia
FROM julia:1.10

# Actualizar el sistema e instalar las dependencias necesarias
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    wget \
    git \
    build-essential \
    libcurl4-openssl-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio de trabajo
WORKDIR /workspace

# Clonar el repositorio del paquete
RUN git clone https://github.com/IlianPihlajamaa/OrnsteinZernike.jl

# Instalar los paquetes de Julia necesarios
RUN julia -e 'using Pkg; Pkg.add(PackageSpec(path="/workspace/OrnsteinZernike.jl")); Pkg.instantiate()'
RUN julia -e 'using Pkg; Pkg.add("JSON")'

# Crear directorio para la salida
ENV OUTPUT_DIR="/workspace/particulas"
RUN mkdir -p $OUTPUT_DIR

# Copiar el script que se va a utilizar
COPY OZE2_HS.jl .

# Copiar el script de shell para ejecutar
COPY entrypoint.sh .

# Dar permisos de ejecución al script
RUN chmod +x entrypoint.sh

# Establecer variable de entorno
ENV PARAM=0.1

# Establecer el punto de entrada usando bash explícitamente
ENTRYPOINT ["bash", "./entrypoint.sh"]
```


### `docker-compose.yml`

```yaml
# version: '3.9'
services:
  ornstein-zernike:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: oz_loc_try
    environment:
      - PARAM=${PARAM:-0.1}
    volumes:
      - ./:/workspace
    working_dir: /workspace
    entrypoint: ["./entrypoint.sh"]

# Para ejecutar en PowerShell (Windows):
# $env:PARAM="0.3"; docker-compose up --build
```


---


## Ecuación Ornstein-Zernike para Esferas Duras

Este proyecto contiene un script en Julia que resuelve la ecuación Ornstein-Zernike usando la teoría de esferas duras. La solución se presenta en formato JSON para su posterior análisis. Además, el proyecto incluye un Dockerfile para crear un contenedor que ejecute el script en un entorno controlado.

### Descripción del código `OZE_HS.jl`

- Se obtiene el valor de la fracción volumétrica `phi` como argumento del usuario.
- Se establece un sistema de esferas duras (`HardSpheres`) con densidad `ρ = (6/π) * φ` y temperatura `kBT = 1.0`.
- Se usa el cierre de Percus-Yevick (`PercusYevick`) para resolver la ecuación de Ornstein-Zernike.
- La solución se imprime en formato JSON.

### Dockerfile

El Dockerfile construye una imagen de Docker con:

- Julia y sus dependencias.
- El paquete `OrnsteinZernike.jl` desde GitHub.
- El paquete `JSON.jl`.

Se copian los scripts necesarios (`OZE_HS.jl` y `entrypoint.sh`) y se configura el punto de entrada del contenedor.

### `entrypoint.sh`

Script de shell que:

- Crea un directorio para resultados.
- Ejecuta el script de Julia con el valor `phi`.
- Guarda la salida en un archivo con nombre `result_<phi>.dat`.


### Conclusión

Este proyecto permite resolver la ecuación Ornstein-Zernike de forma reproducible y portátil usando Docker. Puedes ajustar el valor de `phi` y analizar los resultados sin preocuparte por las dependencias del sistema operativo.

 






