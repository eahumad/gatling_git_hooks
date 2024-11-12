#!/bin/bash

## Validar archivos CSV
# recomendado utilizar en pre-commit


# Mensajes de error acumulados
messages=""

# Validar Archivos CSV
check_csv() {
    local file="$1"
    local line_number=0
    local column_count=-1
    local has_errors=false
    local last_line_empty=false
    local filename="\"$file\""

    while IFS= read -r line || [[ -n $line ]]; do
        line_number=$((line_number + 1))

        # Validar lineas vacías
        if [[ -z "$line" ]]; then
            messages+="Error: Archivo con lineas en blanco, linea $line_number en $filename \n\n"
            has_errors=true
            last_line_empty=true
            continue
        else
            last_line_empty=false
        fi

        # Validar caracteres extraños 
        if [[ "$line" =~ [\"\'\`´] ]]; then
            messages+="Error: Caracteres extraños en línea $line_number en $filename\n\n"
            has_errors=true
        fi

        # Validar cantidad de columnas por linea
        current_column_count=$(echo "$line" | awk -F',' '{print NF}')
        if [[ $column_count -eq -1 ]]; then
            column_count=$current_column_count
        elif [[ $current_column_count -ne $column_count ]]; then
            messages+="Error: Línea $line_number en $filename tiene número de columnas inconsistentes (se esperan $column_count, pero hay $current_column_count)\n\n"
            has_errors=true
        fi
    done <"$file"

    # Check if the last line was empty
    if $last_line_empty; then
        messages+="Error: Última línea vacía en $filename\n\n"
        has_errors=true
    fi

    $has_errors && return 1 || return 0
}

# Obtener la lista de archivos CSV preparados para el commit
files=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.csv$')

# Si no hay archivos CSV preparados, salimos
if [[ -z "$files" ]]; then
    printf "No hay archivos CSV preparados. Se continúa sin validar CSV.\n\n"
    exit 0
fi

# Validar cada archivo CSV
error_found=false
while IFS= read -r file; do
    if ! check_csv "$file"; then
        error_found=true
    fi
done <<<"$files"

# Si hubo errores, imprimir todos los mensajes y prevenir el commit
if $error_found; then
    printf "Validación CSV fallida. Por favor corrige los errores antes de realizar el commit:\n\n\n\n$messages\n\n"
    exit 1
fi

printf "Todos los archivos CSV han pasado la validación.\n\n"
exit 0  # Permitir el commit
