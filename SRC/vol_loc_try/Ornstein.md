
 
 
### Ecuación Ornstein-Zernike para Esferas duras

## OZE_HS.jl:  resuelve la ecuación Ornstein-Zernike.

Este proyecto contiene un script en Julia que resuelve la ecuación Ornstein-Zernike usando la teoría de esferas duras. La solución se presenta en formato JSON para su posterior análisis. Además, el proyecto incluye un Dockerfile para crear un contenedor que ejecute el script en un entorno controlado.



## Usando las siguientes funciones

using OrnsteinZernike  // ecuacion de Ornstein Zernike
using JSON           // JSON para la forma el formato

function main(args...)


Se obtiene el valor de la fracción volumétrica phi (especificado por el usuario) a través de los argumentos de línea de comando.
phi es un parámetro que representa la fracción volumétrica de partículas en el sistema.

    # user inputs
    phi_str = args[1][1] // se necesita de phi para los argumentos de la funcion
    #println(phi_str)
    phi = parse(Float64, phi_str)

Se establece un sistema de esferas duras (HardSpheres) con una densidad dada por ρ = (6/π) * φ y una temperatura de la red de kBT = 1.0.
El sistema se define con 3 dimensiones espaciales.

# systema para esferas duras
    dims = 3 // numero de dimensiones
    kBT = 1.0
    ρ = (6/pi)*phi
    potential = HardSpheres(1.0)  # Hard sphere potential (diameter 1.0)
    system = SimpleLiquid(dims, ρ, kBT, potential)

    Se utiliza el cierre de Percus-Yevick (PercusYevick) para resolver la ecuación Ornstein-Zernike, que es un método común en la teoría de líquidos.
    Se resuelve el sistema utilizando el cierre previamente especificado.

# closure relation for the Ornstein-Zernike equation
    closure = PercusYevick() // se utiliza la cerradurta de percus Yevick





 # solving the system using the Ornstein-Zernike closure
    sol = @time solve(system, closure)
La solución del sistema se guarda en formato JSON para su posterior uso o análisis.
# processing and saving the result
    data = Dict("system_solution" => sol) // ingesa al diccionario en system_soution
    json_data = JSON.json(data)

    # printing the solution in JSON format
    println(json_data)
end

main(ARGS)



### Dockerfile

El Dockerfile crea una imagen Docker que contenga un entorno adecuado para ejecutar el script de Julia, instalar las dependencias necesarias, y ejecutar el código dentro de un contenedor que ayuda a crear una imagen de docker.

El archivo que define el proceso de construcción de la imagen Docker con todas las dependencias necesarias, la instalación de Julia, y la ejecución del script de Julia.
entrypoint.sh: Script de shell que se utiliza como punto de entrada al contenedor Docker. Este script configura y ejecuta el código Julia.


Se usa la imagen alpine:latest  como sisterma base ya que es muy pequeña, minimalista y facil de utlizar


FROM alpine:latest


Instalación de Dependencias: Se instalan herramientas esenciales como bash, curl, git y otros paquetes necesarios para la instalación de Julia y el funcionamiento del contenedor.


RUN apk update && \
    apk add --no-cache \
    bash \
    curl \
    build-base \
    libgcc \
    libstdc++ \
    git \
    && rm -rf /var/cache/apk/*


Instalación de Julia: Julia se descarga e instala en el contenedor de la siguiente manera  especificando las instrucciones necesarias para su instalacion.



RUN curl -sSL https://julialang.org/downloads/latest_release.tar.gz | tar -xzC /usr/local
ENV PATH="/usr/local/julia-*/bin:$PATH"


Se clona el repositorio OrnsteinZernike.jl que contiene la implementación de la teoría Ornstein-Zernike.

RUN git clone https://github.com/IlianPihlajamaa/OrnsteinZernike.jl

Utilizamos Repositorio de Julia para la implementación de la ecuación Ornstein-Zernike en el archivo OrnsteinZernike.jl

Instalación de Paquetes en Julia: Se instalan los paquetes de Julia necesarios como OrnsteinZernike.jl y JSON.


RUN julia -e 'using Pkg; Pkg.add(PackageSpec(path="/workspace/OrnsteinZernike.jl")); Pkg.instantiate()'
RUN julia -e 'import Pkg; Pkg.add("JSON")'

Copia de Archivos y Configuración de Permisos: Se copian los scripts de Julia y el script de shell que se utilizarán para ejecutar el programa. Además, se otorgan permisos de ejecución al script de shell.


COPY OZE_HS.jl .  // copia el  archivo OZE_HS.jl 
COPY entrypoint.sh . // copia el acceso al punto de acceso al contenedor docker.
RUN chmod +x entrypoint.sh //entrega permiso de ejecucion.


Configuración del Entorno: Se establece la variable de entorno PARAM que puede ser utilizada dentro del contenedor, y se configura el contenedor para que ejecute el script de shell como punto de entrada.

ENV PARAM=0.01
ENTRYPOINT ["./entrypoint.sh"] // entrypoint.sh: Un script de shell que se utiliza como punto de entrada del contenedor Docker.


Descripción del Script Shell (entrypoint.sh)

El archivo entrypoint.sh contiene las instrucciones necesarias para ejecutar el script Julia dentro del contenedor. Es posible que se deba personalizar este archivo según los detalles específicos del entorno de ejecución.


 ## Ejecución del Contenedor Docker

Para ejecutar el contenedor Docker y pasar un parámetro al script Julia, puedes usar el siguiente comando:

docker run --rm -e PARAM=0.01 codigo_app .





--rm: Elimina el contenedor después de que se ejecute.
-e PARAM=0.01: Establece el valor de la variable de entorno PARAM.
codigo_app: El nombre de la imagen Docker.



 ## Conclusiones:


Este proyecto proporciona una forma controlada de ejecutar un script Julia para resolver la ecuación Ornstein-Zernike en un contenedor Docker. Todo el proceso está diseñado para facilitar la ejecución en diferentes entornos sin preocuparse por las dependencias del sistema operativo de acuerdo a lo paramtros de ehjecucion del sistema.







