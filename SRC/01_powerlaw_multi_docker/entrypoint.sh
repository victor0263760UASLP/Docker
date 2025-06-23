
#!/bin/bash

set -euo pipefail

if [[ -z "${EPSILON:-}" || -z "${SIGMA:-}" || -z "${N:-}" || -z "${PHI:-}" || -z "${KBT:-}" || -z "${FOLDER_NAME:-}" ]]; then
  echo "ERROR: Faltan variables de entorno requeridas."
  echo "Define EPSILON, SIGMA, N, PHI, KBT y FOLDER_NAME en el archivo .env o al ejecutar el contenedor."
  exit 1
fi

echo "EPSILON: $EPSILON"
echo "SIGMA: $SIGMA"
echo "N: $N"
echo "PHI: $PHI"
echo "KBT: $KBT"
echo "FOLDER_NAME: $FOLDER_NAME"

LOCAL_PATH="/workspace/$FOLDER_NAME"
VOLUME_PATH="/data_output/$FOLDER_NAME"

mkdir -p "$LOCAL_PATH"
mkdir -p "$VOLUME_PATH"

echo "Local Path: $LOCAL_PATH"
echo "Volume Path: $VOLUME_PATH"

# Verificar que Julia esté disponible
command -v julia >/dev/null 2>&1 || { echo >&2 "Julia no está instalada."; exit 1; }

# Ejecutar el script de Julia
julia power_dockerduo.jl "$EPSILON" "$SIGMA" "$N" "$PHI" "$KBT" "$LOCAL_PATH" "$VOLUME_PATH"