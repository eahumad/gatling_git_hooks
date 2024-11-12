#!/bin/bash

# Lista de palabras clave a buscar en los nombres de las claves
keywords=("id" "sku" "item" "username" "password")

# Mensajes de error acumulados
messages=""

# Validar Archivos
check_keys() {
    local file="$1"
    local line_number=0
    local has_errors=false
    local filename="\"$file\""

    while IFS= read -r line || [[ -n $line ]]; do
        line_number=$((line_number + 1))

        # Buscar si la línea contiene alguna de las palabras clave en el nombre de la clave
        for keyword in "${keywords[@]}"; do
            if [[ "$line" =~ $keyword ]]; then
                # Verificar si la línea asigna un valor que empieza con ${, "${ o [${ 
                if ! [[ "$line" =~ ^[^=]+=[[:space:]]*[\{\"]?[\$][\{\[] ]]; then
                    messages+=$(printf "Error: La clave en la línea $line_number de $filename contiene '$keyword' pero no tiene un valor que comienza con \${, \"\${ o [\${.\n")
                    has_errors=true
                fi
                break
            fi
        done
    done < "$file"

    $has_errors && return 1 || return 0
}

# Obtener la lista de archivos preparados para el commit
files=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.json$')


# Si no hay archivos preparados, salir
if [[ -z "$files" ]]; then
    printf "No hay archivos preparados. Se continúa sin validaciones.\n"
    exit 0
fi

# Validar cada archivo
error_found=false
while IFS= read -r file; do
    if ! check_keys "$file"; then
        error_found=true
    fi
done <<<"$files"

# Si hubo errores, imprimir todos los mensajes y prevenir el commit
if $error_found; then
    printf "Validación fallida. Por favor corrige los errores antes de realizar el commit:\n\n$messages\n"
    exit 1
fi

printf "Todos los archivos han pasado la validación.\n"
exit 0  # Permitir el commit
