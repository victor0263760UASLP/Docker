#!/bin/bash
set -euo pipefail

if [ -z "${D1:-}" ] || [ -z "${D2:-}" ] || [ -z "${RHO_TOTAL:-}" ] || [ -z "${KBT:-}" ] || [ -z "${FOLDER_NAME:-}" ]; then
  echo "ERROR: Faltan variables de entorno requeridas."
  echo "Define D1, D2, RHO_TOTAL, KBT y FOLDER_NAME en el archivo .env o al ejecutar el contenedor."
  exit 1
fi

echo "D1: $D1"
echo "D2: $D2"
echo "RHO_TOTAL: $RHO_TOTAL"
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

command -v julia >/dev/null 2>&1 || { echo >&2 "Julia no está instalada."; exit 1; }

julia mixtures.jl "$D1" "$D2" "$RHO_TOTAL" "$KBT" "$LOCAL_PATH" "$VOLUME_PATH"
