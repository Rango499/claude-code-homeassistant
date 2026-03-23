#!/usr/bin/env bash
# ==============================================================================
# test-local.sh — Probar el servidor Node.js localmente antes de hacer push
#
# Uso (desde la raíz del repositorio):
#   bash test-local.sh
#
# Requisitos: Node.js >= 18, npm
# El script instala las dependencias en una carpeta temporal y arranca el servidor
# en localhost:8099. Abre http://localhost:8099 en tu navegador para ver la UI.
# Pulsa Ctrl+C para detenerlo.
# ==============================================================================

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="${REPO_DIR}/claude-terminal/server"
TEMP_DIR="${REPO_DIR}/.test-deps"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   Claude Code Terminal — Test Local                  ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── Verificar Node.js ──────────────────────────────────────────────────────────
if ! command -v node &>/dev/null; then
    echo "✗ Node.js no está instalado. Instálalo desde https://nodejs.org"
    exit 1
fi
NODE_VERSION=$(node -e "process.stdout.write(process.versions.node)")
echo "✓ Node.js ${NODE_VERSION}"

# ── Instalar dependencias en carpeta temporal ──────────────────────────────────
mkdir -p "${TEMP_DIR}"
cp "${SERVER_DIR}/package.json" "${TEMP_DIR}/"

echo "⟳ Instalando dependencias del servidor..."
(cd "${TEMP_DIR}" && npm install --production --loglevel=error 2>&1 | tail -3)
echo "✓ Dependencias instaladas"

# ── Variables de entorno simuladas (sin Home Assistant real) ──────────────────
export UI_PORT=8099
export SUPERVISOR_TOKEN=""
export HA_WORKING_DIR="${HOME}"
export HA_AUTO_LAUNCH="false"
export HA_SKIP_PERMISSIONS="false"
export HA_THEME_NAME="dark"
export HA_FONT_SIZE="14"
export HA_THEME_JSON='{"background":"#1e1e1e","foreground":"#d4d4d4","cursor":"#d4d4d4","selection":"rgba(255,255,255,0.15)","black":"#1e1e1e","red":"#f44747","green":"#608b4e","yellow":"#dcdcaa","blue":"#569cd6","magenta":"#c678dd","cyan":"#4ec9b0","white":"#d4d4d4","brightBlack":"#808080","brightRed":"#f44747","brightGreen":"#608b4e","brightYellow":"#dcdcaa","brightBlue":"#569cd6","brightMagenta":"#c678dd","brightCyan":"#4ec9b0","brightWhite":"#ffffff"}'

# Apuntar node_modules al dir temporal
export NODE_PATH="${TEMP_DIR}/node_modules"

echo ""
echo "────────────────────────────────────────────────────────"
echo "  Servidor arrancando en → http://localhost:8099"
echo "  Terminal disponible en  → http://localhost:8099 (pestaña Claude Terminal)"
echo "  Pulsa Ctrl+C para detener"
echo "────────────────────────────────────────────────────────"
echo ""

# Crear node_modules symlink en server dir si no existe (para require())
if [ ! -d "${SERVER_DIR}/node_modules" ]; then
    ln -sf "${TEMP_DIR}/node_modules" "${SERVER_DIR}/node_modules"
    LINKED=1
fi

# Limpiar al salir
cleanup() {
    echo ""
    echo "⟳ Limpiando..."
    if [ "${LINKED:-0}" = "1" ] && [ -L "${SERVER_DIR}/node_modules" ]; then
        rm -f "${SERVER_DIR}/node_modules"
    fi
    echo "✓ Listo"
}
trap cleanup EXIT INT TERM

# Arrancar el servidor
node "${SERVER_DIR}/index.js"
