#!/bin/bash
set -euo pipefail

# Verificar variables de entorno
if [ -z "${PHI:-}" ]  || [ -z "${FOLDER_NAME:-}" ]; then
  echo "ERROR: Faltan variables de entorno requeridas."
  echo "Define PHI, FOLDER_NAME en el archivo .env o al ejecutar el contenedor."
  exit 1
fi


echo "PHI: $PHI"
echo "FOLDER_NAME: $FOLDER_NAME"


LOCAL_PATH="/workspace/$FOLDER_NAME"
VOLUME_PATH="/data_output/$FOLDER_NAME"


mkdir -p "$LOCAL_PATH"
mkdir -p "$VOLUME_PATH"


echo "Local Path: $LOCAL_PATH"
echo "Volume Path: $VOLUME_PATH"


# Verificar que Julia está instalada.
command -v julia >/dev/null 2>&1 || { echo >&2 "Julia no está instalada."; exit 1; }


julia scgle.jl "$PHI"  "$LOCAL_PATH" "$VOLUME_PATH"
