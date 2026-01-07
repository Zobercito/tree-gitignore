#!/bin/bash
# tree_ignore - Muestra estructura usando la lógica nativa de Git
# Uso: tree_ignore [directorio] [opciones_extra_de_tree]

dir="${1:-.}"
shift 

# Verificar tree
if ! command -v tree &>/dev/null; then
    echo "Error: 'tree' no está instalado."
    exit 1
fi

# --- CORRECCIÓN DE PORTABILIDAD (Reemplaza realpath) ---
if [ -d "$dir" ]; then
    # Obtenemos ruta absoluta de forma compatible con todos los sistemas
    abs_dir=$(cd "$dir" && pwd)
    dir_name=$(basename "$abs_dir")
else
    echo "Error: '$dir' no es un directorio válido o no existe."
    exit 1
fi

cd "$abs_dir" 2>/dev/null || {
    echo "Error: No se puede acceder a '$dir'"
    exit 1
}

# --- LÓGICA ---

# 1. Comprobar si estamos dentro de un repositorio Git
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # Estamos en Git: Usamos la fuente de verdad de Git
    echo " "
    git ls-files --cached --others --exclude-standard | tree --fromfile . "$@" | sed "1s|^\.$|$dir_name/|"

else
    # 2. NO estamos en Git: Usamos tu método original (Fallback)
    echo " "
    
    ignore_patterns=""
    if [ -f ".gitignore" ]; then
        ignore_patterns=$(grep -v '^[[:space:]]*#' .gitignore | \
            grep -v '^[[:space:]]*$' | \
                tr '\n' '|' | \
                    sed 's/|$//')
    fi

    # Mantenemos tu lógica exacta: oculta .git y archivos que empiezan con punto
    if [ -n "$ignore_patterns" ]; then
        ignore_patterns="${ignore_patterns}|\.git|.*"
    else
        ignore_patterns="\.git|.*"
    fi

    tree -I "$ignore_patterns" "$@" | sed "1s|^\.$|$dir_name/|; 1s|^\. |$dir_name/ |"
fi

cd - >/dev/null 2>&1
