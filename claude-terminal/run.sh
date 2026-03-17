#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Add-on: Claude Code Terminal
# Script principal de arranque
# ==============================================================================

set -e

bashio::log.info "Iniciando Claude Code Terminal..."

# ==============================================================================
# Leer configuración del addon
# ==============================================================================
AUTO_LAUNCH=$(bashio::config 'auto_launch_claude')
SKIP_PERMISSIONS=$(bashio::config 'dangerously_skip_permissions')
WORKING_DIR=$(bashio::config 'working_directory')
THEME=$(bashio::config 'theme')
FONT_SIZE=$(bashio::config 'font_size')
CUSTOM_CLAUDE_MD=$(bashio::config 'custom_claude_md')

bashio::log.info "Directorio de trabajo: ${WORKING_DIR}"
bashio::log.info "Auto-launch Claude: ${AUTO_LAUNCH}"
bashio::log.info "Tema: ${THEME}, Tamaño fuente: ${FONT_SIZE}"

# ==============================================================================
# Crear directorio de trabajo si no existe
# ==============================================================================
if [ ! -d "${WORKING_DIR}" ]; then
    bashio::log.warning "El directorio ${WORKING_DIR} no existe, usando /config"
    WORKING_DIR="/config"
fi

# ==============================================================================
# Instalar paquetes adicionales del sistema (configurados por el usuario)
# ==============================================================================
EXTRA_PACKAGES=$(bashio::config 'extra_packages')
if [ -n "${EXTRA_PACKAGES}" ] && [ "${EXTRA_PACKAGES}" != "[]" ]; then
    bashio::log.info "Instalando paquetes adicionales del sistema..."
    echo "${EXTRA_PACKAGES}" | jq -r '.[]' | xargs -r apt-get install -y --no-install-recommends
fi

# ==============================================================================
# Instalar paquetes adicionales de Python (configurados por el usuario)
# ==============================================================================
EXTRA_PIP=$(bashio::config 'extra_pip_packages')
if [ -n "${EXTRA_PIP}" ] && [ "${EXTRA_PIP}" != "[]" ]; then
    bashio::log.info "Instalando paquetes pip adicionales..."
    echo "${EXTRA_PIP}" | jq -r '.[]' | xargs -r pip3 install --no-cache-dir --break-system-packages
fi

# ==============================================================================
# Configurar CLAUDE.md con contexto de Home Assistant
# ==============================================================================
/usr/share/claude-terminal/scripts/setup-claude-md.sh "${WORKING_DIR}" "${CUSTOM_CLAUDE_MD}"

# ==============================================================================
# Configurar variables de entorno para Claude Code
# ==============================================================================
export HOME=/root
export CLAUDE_CONFIG_DIR="/data/claude-config"
mkdir -p "${CLAUDE_CONFIG_DIR}"

# Symlink para que Claude Code persista la auth entre reinicios
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
        bashio::log.warning "Modo dangerously_skip_permissions activado - Claude Code tendrá acceso total"
        BASH_CMD="${BASH_CMD} claude --dangerously-skip-permissions"
    else
        BASH_CMD="${BASH_CMD} claude"
    fi
else
    # Solo abrir bash normal en el directorio correcto
    BASH_CMD="${BASH_CMD} exec bash"
fi

bashio::log.info "Iniciando ttyd en puerto 7681 (interno)..."

# ==============================================================================
# Iniciar ttyd en background (accedido via proxy desde el servidor principal)
# ==============================================================================
ttyd \
    --port 7681 \
    --interface 127.0.0.1 \
    --title-format "Claude Code Terminal" \
    --theme "${THEME}" \
    --font-size "${FONT_SIZE}" \
    --writable \
    --max-clients 10 \
    --ping-interval 30 \
    bash -c "${BASH_CMD}" &

TTYD_PID=$!
bashio::log.info "ttyd iniciado (PID: ${TTYD_PID})"

# Esperar a que ttyd arranque
sleep 2

# ==============================================================================
# Iniciar servidor web principal (editor de planos + proxy terminal)
# ==============================================================================
bashio::log.info "Iniciando interfaz principal en puerto 8099..."
export UI_PORT=8099

exec node /usr/share/claude-terminal/server/index.js
