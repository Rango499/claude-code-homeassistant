#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Add-on: Claude Code Terminal
# Script principal de arranque
# Lee la configuración directamente desde /data/options.json con jq
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
    THEME="dark"
    FONT_SIZE="14"
    CUSTOM_CLAUDE_MD=""
else
    AUTO_LAUNCH=$(jq -r '.auto_launch_claude // true' "${OPTIONS_FILE}")
    SKIP_PERMISSIONS=$(jq -r '.dangerously_skip_permissions // false' "${OPTIONS_FILE}")
    WORKING_DIR=$(jq -r '.working_directory // "/config"' "${OPTIONS_FILE}")
    THEME=$(jq -r '.theme // "dark"' "${OPTIONS_FILE}")
    FONT_SIZE=$(jq -r '.font_size // 14' "${OPTIONS_FILE}")
    CUSTOM_CLAUDE_MD=$(jq -r '.custom_claude_md // ""' "${OPTIONS_FILE}")
fi

echo "[INFO] Directorio de trabajo: ${WORKING_DIR}"
echo "[INFO] Auto-launch Claude: ${AUTO_LAUNCH}"
echo "[INFO] Tema: ${THEME}, Tamaño fuente: ${FONT_SIZE}"

# ==============================================================================
# Usar /config como fallback si el directorio no existe
# ==============================================================================
if [ ! -d "${WORKING_DIR}" ]; then
    echo "[WARNING] El directorio ${WORKING_DIR} no existe, usando /config"
    WORKING_DIR="/config"
fi

# ==============================================================================
# Instalar paquetes adicionales del sistema (configurados por el usuario)
# ==============================================================================
EXTRA_PACKAGES=$(jq -r '.extra_packages // [] | .[]' "${OPTIONS_FILE}" 2>/dev/null || true)
if [ -n "${EXTRA_PACKAGES}" ]; then
    echo "[INFO] Instalando paquetes adicionales del sistema..."
    apt-get update -qq
    echo "${EXTRA_PACKAGES}" | xargs -r apt-get install -y --no-install-recommends -qq
    rm -rf /var/lib/apt/lists/*
fi

# ==============================================================================
# Instalar paquetes adicionales de Python (configurados por el usuario)
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
# Construir el comando de arranque del terminal
# ==============================================================================
BASH_CMD="cd ${WORKING_DIR} && "

if [ "${AUTO_LAUNCH}" = "true" ]; then
    if [ "${SKIP_PERMISSIONS}" = "true" ]; then
        echo "[WARNING] Modo dangerously_skip_permissions activado"
        BASH_CMD="${BASH_CMD}claude --dangerously-skip-permissions"
    else
        BASH_CMD="${BASH_CMD}claude"
    fi
else
    BASH_CMD="${BASH_CMD}exec bash"
fi

# ==============================================================================
# Copiar bashrc personalizado al home del usuario
# ==============================================================================
cp /usr/share/claude-terminal/bashrc "${HOME}/.bashrc" 2>/dev/null || true

# ==============================================================================
# Crear directorio www/floorplans si no existe
# ==============================================================================
mkdir -p /config/www/floorplans 2>/dev/null || true

# ==============================================================================
# Iniciar ttyd en background (solo escucha en localhost)
# ==============================================================================
echo "[INFO] Iniciando ttyd en puerto 7681 (interno)..."

ttyd \
    --port 7681 \
    --interface 127.0.0.1 \
    --title-format "Claude Code Terminal" \
    --theme "${THEME}" \
    --font-size "${FONT_SIZE}" \
    --writable \
    --max-clients 10 \
    --ping-interval 30 \
    bash --rcfile "${HOME}/.bashrc" -c "${BASH_CMD}" &

TTYD_PID=$!
echo "[INFO] ttyd iniciado (PID: ${TTYD_PID})"

# Esperar a que ttyd arranque
sleep 2

# ==============================================================================
# Iniciar servidor web principal (editor de planos + proxy terminal)
# ==============================================================================
echo "[INFO] Iniciando interfaz principal en puerto 8099..."
export UI_PORT=8099

exec node /usr/share/claude-terminal/server/index.js
