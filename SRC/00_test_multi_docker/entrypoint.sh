#!/bin/bash
set -euo pipefail

# Verificar variables de entorno
if [ -z "${PHI:-}" ] || [ -z "${KBT:-}" ] || [ -z "${FOLDER_NAME:-}" ]; then
  echo "ERROR: Faltan variables de entorno requeridas."
  echo "Define PHI, KBT y FOLDER_NAME en el archivo .env o al ejecutar el contenedor."
  exit 1
fi


echo "PHI: $PHI"
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

# Verificar que Julia está instalada.
command -v julia >/dev/null 2>&1 || { echo >&2 "Julia no está instalada."; exit 1; }


julia OZE5.jl "$PHI" "$KBT" "$LOCAL_PATH" "$VOLUME_PATH"
