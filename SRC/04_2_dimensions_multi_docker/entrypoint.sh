#!/bin/bash
set -euo pipefail

if [ -z "${DENSITIES:-}" ] || [ -z "${DIMENSION:-}" ] || [ -z "${KBT:-}" ] || [ -z "${FOLDER_NAME:-}" ]; then
  echo "ERROR: Faltan variables de entorno requeridas."
  echo "Define densidades, dimensiones, KBT y FOLDER_NAME en el archivo .env o al ejecutar el contenedor."
  exit 1
fi

echo "Densities: $DENSITIES"
echo "Dimension: $DIMENSION"
echo "KBT: $KBT"
echo "Folder Name: $FOLDER_NAME"
echo ""

LOCAL_PATH="/workspace/$FOLDER_NAME"
VOLUME_PATH="/data_output/$FOLDER_NAME"

mkdir -p "$LOCAL_PATH"
mkdir -p "$VOLUME_PATH"

echo "Local Path: $LOCAL_PATH"
echo "Volume Path: $VOLUME_PATH"
echo ""

command -v julia >/dev/null 2>&1 || { echo >&2 "Julia no está instalada."; exit 1; }

julia density.jl "$DENSITIES" "$DIMENSION" "$KBT" "$LOCAL_PATH" "$VOLUME_PATH"
