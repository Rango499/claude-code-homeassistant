#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Add-on: Claude Code Terminal
# Script principal de arranque
# ==============================================================================

set -e

echo "[INFO] Iniciando Claude Code Terminal..."

# ==============================================================================
# Leer configuración del addon desde /data/options.json
# ==============================================================================
OPTIONS_FILE="/data/options.json"

if [ ! -f "${OPTIONS_FILE}" ]; then
    echo "[WARNING] No se encontró ${OPTIONS_FILE}, usando valores por defecto"
    AUTO_LAUNCH="true"
    SKIP_PERMISSIONS="false"
    WORKING_DIR="/config"
    THEME_NAME="dark"
    FONT_SIZE="14"
    CUSTOM_CLAUDE_MD=""
else
    AUTO_LAUNCH=$(jq -r '.auto_launch_claude // true' "${OPTIONS_FILE}")
    SKIP_PERMISSIONS=$(jq -r '.dangerously_skip_permissions // false' "${OPTIONS_FILE}")
    WORKING_DIR=$(jq -r '.working_directory // "/config"' "${OPTIONS_FILE}")
    THEME_NAME=$(jq -r '.theme // "dark"' "${OPTIONS_FILE}")
    FONT_SIZE=$(jq -r '.font_size // 14' "${OPTIONS_FILE}")
    CUSTOM_CLAUDE_MD=$(jq -r '.custom_claude_md // ""' "${OPTIONS_FILE}")
fi

echo "[INFO] Directorio de trabajo: ${WORKING_DIR}"
echo "[INFO] Auto-launch Claude: ${AUTO_LAUNCH}"
echo "[INFO] Tema: ${THEME_NAME}, Tamaño fuente: ${FONT_SIZE}"

# ==============================================================================
# Mapear nombre de tema a JSON de xterm.js (formato que entiende ttyd)
# ==============================================================================
case "${THEME_NAME}" in
    light)
        THEME_JSON='{"background":"#ffffff","foreground":"#1e1e1e","cursor":"#1e1e1e","cursorAccent":"#ffffff","selection":"rgba(0,0,0,0.2)","black":"#000000","red":"#cd3131","green":"#00bc00","yellow":"#949800","blue":"#0451a5","magenta":"#bc05bc","cyan":"#0598bc","white":"#555555","brightBlack":"#666666","brightRed":"#cd3131","brightGreen":"#14ce14","brightYellow":"#b5ba00","brightBlue":"#0451a5","brightMagenta":"#bc05bc","brightCyan":"#0598bc","brightWhite":"#a5a5a5"}'
        ;;
    solarized)
        THEME_JSON='{"background":"#002b36","foreground":"#839496","cursor":"#839496","selection":"rgba(255,255,255,0.1)","black":"#073642","red":"#dc322f","green":"#859900","yellow":"#b58900","blue":"#268bd2","magenta":"#d33682","cyan":"#2aa198","white":"#eee8d5","brightBlack":"#002b36","brightRed":"#cb4b16","brightGreen":"#586e75","brightYellow":"#657b83","brightBlue":"#839496","brightMagenta":"#6c71c4","brightCyan":"#93a1a1","brightWhite":"#fdf6e3"}'
        ;;
    monokai)
        THEME_JSON='{"background":"#272822","foreground":"#f8f8f2","cursor":"#f8f8f2","selection":"rgba(255,255,255,0.15)","black":"#272822","red":"#f92672","green":"#a6e22e","yellow":"#f4bf75","blue":"#66d9ef","magenta":"#ae81ff","cyan":"#a1efe4","white":"#f8f8f2","brightBlack":"#75715e","brightRed":"#f92672","brightGreen":"#a6e22e","brightYellow":"#f4bf75","brightBlue":"#66d9ef","brightMagenta":"#ae81ff","brightCyan":"#a1efe4","brightWhite":"#f9f8f5"}'
        ;;
    dark|*)
        THEME_JSON='{"background":"#1e1e1e","foreground":"#d4d4d4","cursor":"#d4d4d4","selection":"rgba(255,255,255,0.15)","black":"#1e1e1e","red":"#f44747","green":"#608b4e","yellow":"#dcdcaa","blue":"#569cd6","magenta":"#c678dd","cyan":"#4ec9b0","white":"#d4d4d4","brightBlack":"#808080","brightRed":"#f44747","brightGreen":"#608b4e","brightYellow":"#dcdcaa","brightBlue":"#569cd6","brightMagenta":"#c678dd","brightCyan":"#4ec9b0","brightWhite":"#ffffff"}'
        ;;
esac

# ==============================================================================
# Usar /config como fallback si el directorio no existe
# ==============================================================================
if [ ! -d "${WORKING_DIR}" ]; then
    echo "[WARNING] El directorio ${WORKING_DIR} no existe, usando /config"
    WORKING_DIR="/config"
fi

# ==============================================================================
# Instalar paquetes adicionales del sistema
# ==============================================================================
EXTRA_PACKAGES=$(jq -r '.extra_packages // [] | .[]' "${OPTIONS_FILE}" 2>/dev/null || true)
if [ -n "${EXTRA_PACKAGES}" ]; then
    echo "[INFO] Instalando paquetes adicionales del sistema..."
    apt-get update -qq
    echo "${EXTRA_PACKAGES}" | xargs -r apt-get install -y --no-install-recommends -qq
    rm -rf /var/lib/apt/lists/*
fi

# ==============================================================================
# Instalar paquetes adicionales de Python
# ==============================================================================
EXTRA_PIP=$(jq -r '.extra_pip_packages // [] | .[]' "${OPTIONS_FILE}" 2>/dev/null || true)
if [ -n "${EXTRA_PIP}" ]; then
    echo "[INFO] Instalando paquetes pip adicionales..."
    echo "${EXTRA_PIP}" | xargs -r pip3 install --no-cache-dir --break-system-packages -q
fi

# ==============================================================================
# Configurar CLAUDE.md con contexto de Home Assistant
# ==============================================================================
/usr/share/claude-terminal/scripts/setup-claude-md.sh "${WORKING_DIR}" "${CUSTOM_CLAUDE_MD}" || true

# ==============================================================================
# Configurar directorios persistentes para la auth de Claude Code
# ==============================================================================
export HOME=/root
export CLAUDE_CONFIG_DIR="/data/claude-config"
mkdir -p "${CLAUDE_CONFIG_DIR}"

if [ ! -L "${HOME}/.claude" ]; then
    mkdir -p "${CLAUDE_CONFIG_DIR}/.claude"
    ln -sf "${CLAUDE_CONFIG_DIR}/.claude" "${HOME}/.claude"
fi

# ==============================================================================
# Exportar variables para que el .bashrc y Node.js las usen
# ==============================================================================
export HA_AUTO_LAUNCH="${AUTO_LAUNCH}"
export HA_SKIP_PERMISSIONS="${SKIP_PERMISSIONS}"
export HA_WORKING_DIR="${WORKING_DIR}"
export HA_THEME_JSON="${THEME_JSON}"
export HA_FONT_SIZE="${FONT_SIZE}"

# ==============================================================================
# Construir el .bashrc final combinando base + auto-launch
# ==============================================================================
cp /usr/share/claude-terminal/bashrc "${HOME}/.bashrc"

cat >> "${HOME}/.bashrc" << 'BASHRC_APPEND'

# ── Auto-launch Claude Code (configurado desde el addon) ──────────────────────
if [ "${HA_AUTO_LAUNCH:-true}" = "true" ] && [ -t 0 ]; then
    cd "${HA_WORKING_DIR:-/config}"
    if [ "${HA_SKIP_PERMISSIONS:-false}" = "true" ]; then
        claude --dangerously-skip-permissions
    else
        claude
    fi
    # Cuando Claude termina, queda un bash interactivo normal
    echo ""
    echo "  Claude Code cerrado. Escribe 'claude' para volver a iniciarlo."
    cd "${HA_WORKING_DIR:-/config}"
fi
BASHRC_APPEND

# ==============================================================================
# Crear directorio www/floorplans si no existe
# ==============================================================================
mkdir -p /config/www/floorplans 2>/dev/null || true

# ==============================================================================
# Iniciar ttyd — comando mínimo y estable
# NO usamos --base-path ni -t (opciones de tema): el front-end xterm.js
# se conecta directamente al WebSocket /ws de ttyd y aplica el tema por su cuenta.
# Esto evita el segfault que causaban --base-path /terminal y -t "theme=...".
# ==============================================================================
echo "[INFO] Iniciando ttyd en puerto 7681 (interno)..."

ttyd \
    --port 7681 \
    --interface 127.0.0.1 \
    --writable \
    --max-clients 10 \
    --ping-interval 30 \
    bash -i &

TTYD_PID=$!
echo "[INFO] ttyd iniciado (PID: ${TTYD_PID})"

# Esperar a que ttyd esté listo
sleep 3

# ==============================================================================
# Iniciar servidor web principal (editor de planos + proxy terminal)
# ==============================================================================
echo "[INFO] Iniciando interfaz principal en puerto 8099..."
export UI_PORT=8099

exec node /usr/share/claude-terminal/server/index.js
