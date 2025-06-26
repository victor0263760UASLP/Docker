# Docker
Este manual forma parte de una tesis de licenciatura(Ingenieria en Nanotecnologia y Energias Renovables) del estudiante Rivera Juárez Victor Guadalupe de la UASLP,El propósito general es el aprendizaje de las herramientas fundamentales de docker.

El siguiente repositorio es necesario a la hora de administrar y generar datos en teoria coloidal, dentro de las propiedades estáticas y dinámicas.

En este caso en este repositorio se encuentran varios archivos que encuentran con su archivo.jl,docker compose,archivo.env,entrypoint así como su Dockerfile, necesarios para generar volumenes y carpetas que contienen los archivos generados en .dat de  g(r) y S(K),en este caso usando la ecuación de ornstein Zernike, pero se pueden agregar más librerias en estado y fuera de equilibrio , así como algunos se encuentran automatizados para generar graficas solo añadiendo en la terminal las variables que necesitas.

Existen dos carpetas  el volumenozeDockerM , estos archivos son diferentes por que son como el espoiler de lo que fuimos desarrollando , en esto deben ingresar y cambiar el nombre de la carpeta manualmente en el entrypoint y te genera un volumen en docker desktop  con la carpeta  y archivos .dat y en la carpeta local try_local no se genera volumen en docker desktop solo localmente.

En todas las demás carpetas el codigo se encuentra mejorado para que desde la terminal puedas agregar el nombre de la carpeta, cambiar el valor de muchas variables y hacer graficas de g(r) y S(k), asi como de densidades de rampa , MCT etc.

Estos archivos se encuentran disponibles para realizar las modificaciones pertinentes de acuerdo a las necesidades del estudiante o investigador, agregar variables, más potenciales de interacción, más cerraduras etc.

Todos los codigos del repositorio se encuentran bajo protección de derechos de autor y solo se puede hacer uso bajo la administración del autor de la tesis o de los asesores el Dr.Ricardo Peredo Ortiz y el Dr.Magdaleno Medina Noyola.

Dentro de las consideraciones que te pueden ayudar son : cuando son muchas iteraciones el sistema puede encontrar más rapido convergencias, en el caso de la teoria MCT,algunos parametros son complicados para converger, por lo que tienes que detenerte un poco para ver o imaginarte bajo que parametros puede existir convergencia y en algunos casos puedes hacer algunas operaciones básicas en tu libreta para llevarte un poco de menor tiempo realizando las  combinaciones donde exista convergencia.
En algunas veces es necesario agregar permisos y utilizar el comando  dos2unix ,también puedes utilizar el comando de .gittattributes, a veces es necesario, puede que nunca se ha necesario, si cambias manualmente en Visual Studio Code el formato LF,al principio era necesario por que estaba adaptando el codigo para que funcionara en mac os,Windows y ubuntu y después ya no fue necesario utilizarlo.

##  Uso del archivo `.gitattributes` para control de EOL y binarios

Para asegurar que los saltos de línea (EOL) y los archivos binarios se manejen correctamente en Git, sigue estos pasos:

### 1. Crear el archivo `.gitattributes`

Guarda el siguiente contenido como `.gitattributes` en la raíz de tu repositorio:

```gitattributes
# Archivos de texto: usar saltos de línea LF
*.sh         text eol=lf
*.jl         text eol=lf
Dockerfile   text eol=lf
*.yml        text eol=lf
.env         text eol=lf
*.txt        text eol=lf
*.md         text eol=lf

# Archivos binarios: no tocar EOL
*.png        binary
*.jpg        binary
*.jpeg       binary
*.gif        binary
```

### 2. Añadir el archivo a Git

Ejecuta en tu terminal Git:

```bash
git add .gitattributes
git commit -m "Añadir .gitattributes para control de EOL y binarios"
```

### 3. Renormalizar todos los archivos del repositorio

Esto hará que Git reanalice y actualice los archivos según las reglas de `.gitattributes`:

```bash
git add --renormalize .
git commit -m "Normalizar archivos con nueva configuración de EOL"
```

>  Nota: Este paso puede generar muchos cambios si los archivos tenían saltos de línea inconsistentes.

---

Con esto, tus codigos quedará configurado para manejar correctamente los archivos de texto y binarios, evitando conflictos comunes entre sistemas operativos.
Sin más por el momento adelante te va ayudar mucho, te deseo suerte, todo va estar documentado, recuerda que en la tesis encontraras una descripción de docker y comandos básicos, pero si  tienes alguna duda no dudes en preguntarnos.

Nos vemos hasta luego gracias,suerte en tu camino.

