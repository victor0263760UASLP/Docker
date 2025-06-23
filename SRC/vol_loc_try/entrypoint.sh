#!/bin/bash
# Directorio de salida
OUTPUT_DIR="/workspace/particulas1"

# Asegurarse de que el directorio existe
mkdir -p "$OUTPUT_DIR"

# Ejecutar el script de Julia y guardar la salida en un archivo
julia OZE2_HS.jl "$PARAM" > "$OUTPUT_DIR/result_$PARAM.dat"
