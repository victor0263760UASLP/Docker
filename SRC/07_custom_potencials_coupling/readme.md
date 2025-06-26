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

## Variables del archivo `.env`

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

##  Contenido de Código Fuente

<details><summary><code>mct.jl</code></summary>

```julia

using OrnsteinZernike
using ModeCouplingTheory
using Plots
using DelimitedFiles

const OZ = OrnsteinZernike
const MCT = ModeCouplingTheory

function main(args...)
    if length(args) < 10
        println("Se requieren 10 argumentos: σ z kBT φ M N_stages max_iter chi_list local_folder volume_folder")
        return
    end

    σ            = parse(Float64, args[1])
    z            = parse(Float64, args[2])
    kBT          = parse(Float64, args[3])
    φ            = parse(Float64, args[4])
    M            = parse(Int, args[5])
    N_stages     = parse(Int, args[6])
    max_iter     = parse(Int, args[7])
    chi_list     = parse.(Float64, split(args[8], ","))
    local_folder = args[9]
    volume_folder = args[10]

    mkpath(local_folder)
    mkpath(volume_folder)

    for χ in chi_list
        println(">> Procesando χ = $χ")

        # --- Parámetros del sistema
        κ = σ / 566.02
        p = (λB = 0.71432 / σ, σ = 1.0, κ = κ, z = -z)
        function Yukawa_R(r, p)
            κa = p.κ * 0.5 * p.σ
            LB = (p.z^2) * p.λB * exp(2 * κa) / (1 + κa)^2
            return LB * exp(-p.κ * r) / r
        end

        potential = OZ.CustomPotential(Yukawa_R, p)
        ρ = (6 / π) * φ
        system = OZ.SimpleLiquid(3, ρ, kBT, potential)
        closure = OZ.HypernettedChain()
        dr = 200.0 / M
        method = OZ.NgIteration(M = M; dr = dr, max_iterations = max_iter, N_stages = N_stages)
        method_ramp = OZ.DensityRamp(method, [ρ * χ])

        # --- Resolver OZ
        sol = OZ.solve(system, closure, method_ramp)[1]
        k = sol.k
        S = sol.Sk
        r = sol.r
        g = sol.gr

        # --- Guardar S(k) y g(r)
        base = "phi_$(replace(string(φ), "." => "_"))_chi_$(replace(string(χ), "." => "_"))"
        writedlm(joinpath(local_folder, "Sk_" * base * ".dat"), [k S])
        writedlm(joinpath(volume_folder, "Sk_" * base * ".dat"), [k S])
        writedlm(joinpath(local_folder, "gr_" * base * ".dat"), [r g])
        writedlm(joinpath(volume_folder, "gr_" * base * ".dat"), [r g])

        # --- Graficar S(k) y g(r)
        plot(k, S, xlabel="k", ylabel="S(k)", lw=2, title="S(k)")
        savefig(joinpath(local_folder, "Sk_" * base * ".svg"))
        savefig(joinpath(volume_folder, "Sk_" * base * ".svg"))

        plot(r, g, xlabel="r", ylabel="g(r)", lw=2, title="g(r)")
        savefig(joinpath(local_folder, "gr_" * base * ".svg"))
        savefig(joinpath(volume_folder, "gr_" * base * ".svg"))

        # --- Resolver MCT
        Nk = length(k)
        k_all = [k; k]
        S_all = [ones(Nk); S]
        ∂F0 = zeros(2 * Nk)
        α, β, δ = 0.0, 1.0, 0.0
        γ = @. k_all^2 / S_all
        kernel = MCT.SCGLEKernel(φ, k_all, S_all)
        equation = MCT.MemoryEquation(α, β, γ, δ, S_all, ∂F0, kernel)
        solver = MCT.TimeDoublingSolver(Δt=1e-5, t_max=1e10, N=8, tolerance=1e-8)

        sol_mct = MCT.solve(equation, solver)

        # --- Guardar y graficar Fs(k,t)
        idx = 25  # índice representativo
        t = MCT.get_t(sol_mct)[1:10:end]
        Fskt = MCT.get_F(sol_mct, 1:10:length(t)*10, idx) ./ S_all[idx]
        datos = [log10.(t) Fskt]
        writedlm(joinpath(local_folder, "Fskt_" * base * ".dat"), datos, header="log10(t) Fs(k,t)")
        writedlm(joinpath(volume_folder, "Fskt_" * base * ".dat"), datos, header="log10(t) Fs(k,t)")

        plot(log10.(t), Fskt, xlabel="log10(t)", ylabel="Fs(k,t)", lw=2, title="Fs(k,t)")
        savefig(joinpath(local_folder, "Fskt_" * base * ".svg"))
        savefig(joinpath(volume_folder, "Fskt_" * base * ".svg"))

        println(" Datos guardados para χ = $χ\n")
    end
end

main(ARGS...)



```
</details>

<details><summary><code>entrypoint.sh</code></summary>

```bash
#!/bin/bash
set -euo pipefail

# Verificar variables de entorno requeridas
if [ -z "${SIGMA:-}" ] || [ -z "${Z:-}" ] || [ -z "${KBT:-}" ] || [ -z "${PHI:-}" ] || [ -z "${M:-}" ] || [ -z "${N_STAGES:-}" ] || [ -z "${MAX_ITER:-}" ] || [ -z "${CHI_LIST_STR:-}" ] || [ -z "${FOLDER_NAME:-}" ]; then
  echo "ERROR: Faltan variables de entorno requeridas."
  echo "Define SIGMA, Z, KBT, PHI, M, N_STAGES, MAX_ITER,   CHI_LIST_STR   y FOLDER_NAME en el archivo .env o al ejecutar el contenedor."
  exit 1
fi

echo "SIGMA: $SIGMA"
echo "Z: $Z"
echo "KBT: $KBT"
echo "PHI: $PHI"
echo "M: $M"
echo "N_STAGES: $N_STAGES"
echo "MAX_ITER: $MAX_ITER"
echo "CHI_LIST_STR: $CHI_LIST_STR  "
echo "FOLDER_NAME: $FOLDER_NAME"

LOCAL_PATH="/workspace/$FOLDER_NAME"
VOLUME_PATH="/data_output/$FOLDER_NAME"

mkdir -p "$LOCAL_PATH"
mkdir -p "$VOLUME_PATH"

echo "Local Path: $LOCAL_PATH"
echo "Volume Path: $VOLUME_PATH"
echo ""

command -v julia >/dev/null 2>&1 || { echo >&2 "Julia no está instalada."; exit 1; }

julia mct.jl "$SIGMA" "$Z" "$KBT" "$PHI" "$M" "$N_STAGES" "$MAX_ITER" "$CHI_LIST_STR " "$LOCAL_PATH" "$VOLUME_PATH"




```
</details>

<details><summary><code>Dockerfile</code></summary>

```dockerfile

FROM julia:1.11


RUN apt-get update && apt-get install -y \
    bash curl wget git build-essential libcurl4-openssl-dev ca-certificates dos2unix \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Clonar el repositorio de Julia
RUN git clone https://github.com/IlianPihlajamaa/OrnsteinZernike.jl
RUN git clone https://github.com/IlianPihlajamaa/ModeCouplingTheory.jl

# Instalar paquetes de Julia necesarios
RUN julia -e 'using Pkg; Pkg.add(PackageSpec(path="OrnsteinZernike.jl")); Pkg.instantiate()'
RUN julia -e 'using Pkg; Pkg.add(PackageSpec(path="ModeCouplingTheory.jl")); Pkg.instantiate()'
RUN julia -e 'using Pkg; Pkg.add("JSON"); Pkg.add("DelimitedFiles")'
RUN julia -e 'using Pkg; Pkg.add(["Plots"])'

COPY mct.jl /workspace/mct.jl
COPY entrypoint.sh /workspace/entrypoint.sh


RUN dos2unix /workspace/entrypoint.sh && chmod +x /workspace/entrypoint.sh

# entrypoint
ENTRYPOINT ["bash", "/workspace/entrypoint.sh"]

# Corregir formato fin de línea y dar permiso de ejecución
#RUN sed -i 's/\r//' /workspace/entrypoint.sh && chmod +x /workspace/entrypoint.sh


#windows$env:PHI="0.23"; $env:KBT="2.0"; $env:FOLDER_NAME="nuevop"; docker compose up --build --force-recreate
#macPHI=0.23 KBT=2.0 FOLDER_NAME=martes docker compose up --build --force-recreate
#ubuntu export PHI=0.23; export KBT=2.0; export FOLDER_NAME=nuevop; docker compose up --build --force-recreate
#julia scgle.jl 0.58 ./output ./shared_volume


```
</details>

<details><summary><code>docker-compose.yml</code></summary>

```yaml

#version: "3.8"

services:
  ornstein-zernike:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: potencials_coupling
    volumes:
      - ./:/workspace
      - ./output_local:/workspace/output
      - volumen_lanimfe:/data_output
    working_dir: /workspace
    environment:
      - SIGMA
      - Z
      - KBT
      - PHI
      - M
      - N_STAGES
      - MAX_ITER
      - CHI_LIST_STR
      - FOLDER_NAME
    entrypoint: ["bash", "./entrypoint.sh"]

volumes:
  volumen_lanimfe:

#$env:SIGMA="1.0"; $env:Z="-3.0"; $env:KBT="1.0"; $env:PHI="0.1"; $env:M="2048"; $env:N_STAGES="5"; $env:MAX_ITER="300"; $env:CHI_LIST_STR="1.0"; $env:FOLDER_NAME="nuevo_hola"; docker compose up --build --force-recreate
#$env:SIGMA="1.0"; $env:Z="-10"; $env:KBT="1.0"; $env:PHI="0.1"; $env:M="1024"; $env:N_STAGES="1"; $env:MAX_ITER="100"; $env:CHI_LIST_STR="1.0"; $env:FOLDER_NAME="phi1"; docker compose up --build --force-recreate
#$env:SIGMA="1.0"; $env:Z="-10"; $env:KBT="1.0"; $env:PHI="0.1"; $env:M="2048"; $env:N_STAGES="4"; $env:MAX_ITER="400"; $env:CHI_LIST_STR="0.1,0.5,1.0"; $env:FOLDER_NAME="phi_0_1_Z_10"; docker compose up --build --force-recreate


```
</details>

---



##  Autor

Víctor Guadalupe Rivera Juárez  
 Junio 2025

---

##  Notas Finales

- Puedes cambiar fácilmente las condiciones físicas editando el `.env`.
- Usa `Ctrl+C` para detener la ejecución al final de una compilación.
