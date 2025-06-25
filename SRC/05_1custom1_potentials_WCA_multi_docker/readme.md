
#  Simulación de Líquidos con Potencial WCA (Lennard-Jones Truncado) en Julia usando Docker

Este proyecto permite simular líquidos simples en 2D usando la ecuación de Ornstein-Zernike con un potencial tipo WCA (Weeks-Chandler-Andersen). Está diseñado para ejecutarse fácilmente mediante Docker.

---

## 📂 Archivos principales

- `WCA.jl`: Script en Julia que realiza la simulación.
- `entrypoint.sh`: Script Bash que prepara la ejecución.
- `Dockerfile`: Define el entorno de Julia y sus dependencias.
- `docker-compose.yml`: Orquesta la ejecución del contenedor.
- `.env`: Define los parámetros físicos de la simulación.

---

##  Variables de entorno

Estas se pueden declarar en un archivo `.env` o directamente en consola.

### Ejemplo de archivo `.env`

```env
PHI=0.5
KBT=1.0
SIGMA=1.0
EPSILON=1.8
FOLDER_NAME=carpeta_dios_gracias17
CLOSURE=PercusYevick
```

---

##  Cómo ejecutar la simulación

**Opción 1: Linux / macOS**

```bash
PHI=0.5 KBT=1.0 SIGMA=1.0 EPSILON=1.8 FOLDER_NAME=carpeta_dios_gracias17 CLOSURE=PercusYevick docker compose up --build --force-recreate
```

**Opción 2: Windows PowerShell**

```powershell
$env:PHI="0.4"; $env:KBT="1.0"; $env:SIGMA="1.0"; $env:EPSILON="1.8"; $env:FOLDER_NAME="sabado_nuevo"; $env:CLOSURE="HNC"; docker compose up --build --force-recreate
```

---

##  Resultados

Los resultados se guardan en:

- Carpeta local: `output_local/carpeta_dios_gracias17/`
- Volumen Docker: `volumen_WCA`

Archivos generados:

- `gdr_phi_<valor>.dat`: función de distribución radial \( g(r) \)
- `sdk_phi_<valor>.dat`: factor de estructura \( S(k) \)

---

##  Requisitos

- Docker + Docker Compose
- Julia >= 1.6 dentro del contenedor
- Repositorio: `OrnsteinZernike.jl`

---

##  Tipos de cerradura soportados

- `py` o `PercusYevick`
- `hnc` o `HypernettedChain`

Este entorno es útil para estudios de estructura de líquidos simples en condiciones controladas mediante simulación teórica.
