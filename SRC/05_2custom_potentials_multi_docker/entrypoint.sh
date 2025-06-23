#!/bin/bash
set -euo pipefail

# Verificar variables de entorno requeridas
if [ -z "${SIGMA:-}" ] || [ -z "${Z:-}" ] || [ -z "${KBT:-}" ] || [ -z "${PHI:-}" ] || [ -z "${M:-}" ] || [ -z "${N_STAGES:-}" ] || [ -z "${MAX_ITER:-}" ] || [ -z "${CHI_LIST:-}" ] || [ -z "${FOLDER_NAME:-}" ]; then
  echo "ERROR: Faltan variables de entorno requeridas."
  echo "Define SIGMA, Z, KBT, PHI, M, N_STAGES, MAX_ITER, CHI_LIST y FOLDER_NAME en el archivo .env o al ejecutar el contenedor."
  exit 1
fi

echo "PHI: $PHI"
echo "KBT: $KBT"
echo "SIGMA: $SIGMA"
echo "Z: $Z"
echo "M: $M"
echo "N_STAGES: $N_STAGES"
echo "MAX_ITER: $MAX_ITER"
echo "CHI_LIST: $CHI_LIST"
echo "FOLDER_NAME: $FOLDER_NAME"

LOCAL_PATH="/workspace/$FOLDER_NAME"
VOLUME_PATH="/data_output/$FOLDER_NAME"

mkdir -p "$LOCAL_PATH"
mkdir -p "$VOLUME_PATH"

echo "Local Path: $LOCAL_PATH"
echo "Volume Path: $VOLUME_PATH"
echo ""

command -v julia >/dev/null 2>&1 || { echo >&2 "Julia no está instalada."; exit 1; }

julia Rampa.jl "$SIGMA" "$Z" "$KBT" "$PHI" "$M" "$N_STAGES" "$MAX_ITER" "$CHI_LIST" "$LOCAL_PATH" "$VOLUME_PATH"


