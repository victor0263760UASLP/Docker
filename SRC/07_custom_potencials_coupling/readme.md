#  Simulación OZ + MCT con Potencial Yukawa en Julia

Este proyecto permite simular líquidos simples interactuando mediante el potencial de Yukawa usando:

- La ecuación de **Ornstein-Zernike (OZ)** con cierre **Hypernetted-Chain (HNC)**.
- La **Teoría del Acoplamiento de Modos (MCT)** para estudiar la dinámica a través de la función Fs(k,t).

Toda la simulación está automatizada y contenida mediante Docker y Docker Compose para asegurar portabilidad.

---

##  Estructura del Proyecto

```bash
 proyecto/
├── mct.jl               # Script principal de simulación OZ + MCT
├── entrypoint.sh        # Script Bash que valida variables y ejecuta el código
├── Dockerfile           # Imagen base Julia + dependencias
├── docker-compose.yml   # Orquesta contenedor y volúmenes
├── .env                 # Archivo con parámetros de simulación
├── output_local/        # Carpeta local para resultados
└── volumen_lanimfe/     # Volumen Docker persistente
```

---

## ⚙️ Variables del archivo `.env`

Ejemplo de configuración usada:

```env
SIGMA=144.0
Z=-440.0
KBT=0.59
PHI=0.00081
M=10000
N_STAGES=50
MAX_ITER=10000
CHI_LIST_STR=0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.95,0.99
FOLDER_NAME=mct_custom
```

---

##  Cómo ejecutar la simulación

### Opción 1: Usar el archivo `.env`

```bash
docker compose up --build --force-recreate
```

---

### Opción 2: Definir variables manualmente

####  En Windows (PowerShell)

```powershell
$env:SIGMA="144.0"
$env:Z="-440.0"
$env:KBT="0.59"
$env:PHI="0.00081"
$env:M="10000"
$env:N_STAGES="50"
$env:MAX_ITER="10000"
$env:CHI_LIST_STR="0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.95,0.99"
$env:FOLDER_NAME="mct_custom"
docker compose up --build --force-recreate
```

####  En macOS / Linux

```bash
export SIGMA=144.0
export Z=-440.0
export KBT=0.59
export PHI=0.00081
export M=10000
export N_STAGES=50
export MAX_ITER=10000
export CHI_LIST_STR="0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.95,0.99"
export FOLDER_NAME="mct_custom"
docker compose up --build --force-recreate
```

---

##  Salidas generadas

Ubicación:

- Carpeta local: `./output_local/mct_custom/`
- Volumen Docker: `volumen_lanimfe/mct_custom/`

Archivos:

- `Sk_phi_<ϕ>_chi_<χ>.dat`: Factor de estructura \( S(k) \)
- `gr_phi_<ϕ>_chi_<χ>.dat`: Distribución radial \( g(r) \)
- `Fskt_phi_<ϕ>_chi_<χ>.dat`: Función de correlación temporal \( F_s(k, t) \)
- Gráficas: `.svg` de cada función física

---

##  Tecnologías usadas

- **Lenguaje:** Julia 1.11
- **Paquetes Julia:**
  - [`OrnsteinZernike.jl`](https://github.com/IlianPihlajamaa/OrnsteinZernike.jl)
  - [`ModeCouplingTheory.jl`](https://github.com/IlianPihlajamaa/ModeCouplingTheory.jl)
  - `Plots`, `DelimitedFiles`, `JSON`
- **Contenedor:** Docker + Docker Compose

---

##  Descripción de Scripts

### `mct.jl`

- Resuelve la estructura \( S(k) \), \( g(r) \) usando OZ con cierre HNC.
- Usa \( S(k) \) para resolver \( F_s(k, t) \) mediante MCT.
- Genera y guarda gráficos y datos automáticamente.

### `entrypoint.sh`

- Verifica que todas las variables de entorno estén definidas.
- Ejecuta el script con los parámetros proporcionados.

---

##  Limpieza de contenedores y volúmenes

```bash
docker compose down --volumes
docker system prune -a --volumes -f
```

---

##  Autor

Víctor Guadalupe Rivera Juárez  
📅 Junio 2025

---

##  Notas Finales

- Puedes cambiar fácilmente las condiciones físicas editando el `.env`.
- Usa `Ctrl+C` para detener la ejecución al final de una compilación.
