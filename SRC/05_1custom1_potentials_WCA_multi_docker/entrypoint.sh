#!/bin/bash
set -euo pipefail

# Verificar variables de entorno
if [ -z "${PHI:-}" ] || [ -z "${KBT:-}" ] || [ -z "${SIGMA:-}" ] || [ -z "${EPSILON:-}" ] || [ -z "${FOLDER_NAME:-}" ] || [ -z "${CLOSURE:-}" ]; then
  echo "ERROR: Faltan variables de entorno requeridas."
  echo "Define PHI, KBT, SIGMA, EPSILON, FOLDER_NAME y CLOSURE en el archivo .env o al ejecutar el contenedor."
  exit 1
fi

echo "PHI: $PHI"
echo "KBT: $KBT"
echo "SIGMA: $SIGMA"
echo "EPSILON: $EPSILON"
echo "FOLDER_NAME: $FOLDER_NAME"
echo "CLOSURE: $CLOSURE"

LOCAL_PATH="/workspace/$FOLDER_NAME"
VOLUME_PATH="/data_output/$FOLDER_NAME"

mkdir -p "$LOCAL_PATH"
mkdir -p "$VOLUME_PATH"

echo "Local Path: $LOCAL_PATH"
echo "Volume Path: $VOLUME_PATH"
echo ""

command -v julia >/dev/null 2>&1 || { echo >&2 "Julia no está instalada."; exit 1; }

julia WCA.jl "$PHI" "$KBT" "$SIGMA" "$EPSILON" "$LOCAL_PATH" "$CLOSURE"
