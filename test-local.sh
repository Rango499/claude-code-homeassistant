#!/usr/bin/env bash
# ==============================================================================
# test-local.sh — Probar el servidor Node.js localmente antes de hacer push
#
# Uso (desde la raíz del repositorio, con Git Bash en Windows):
#   bash test-local.sh
#
# Abre http://localhost:8099 en tu navegador para ver la UI completa.
# Pulsa Ctrl+C para detener.
# ==============================================================================

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="${REPO_DIR}/claude-terminal/server"
# Ruta real de los archivos web (dentro de rootfs, como en el contenedor)
WEB_DIR="${REPO_DIR}/claude-terminal/rootfs/usr/share/claude-terminal/web"
# Carpeta temporal para los planos y datos en test local
TEST_DATA_DIR="${REPO_DIR}/.test-data"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   Claude Code Terminal — Test Local                  ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── Verificar Node.js ──────────────────────────────────────────────────────────
if ! command -v node &>/dev/null; then
    echo "✗ Node.js no encontrado."
    echo "  Instálalo desde https://nodejs.org (versión LTS)"
    echo "  Después reinicia Git Bash y vuelve a ejecutar este script."
    exit 1
fi
NODE_VER=$(node -e "process.stdout.write(process.versions.node)")
echo "✓ Node.js v${NODE_VER}"

# ── Verificar que existen los archivos web ─────────────────────────────────────
if [ ! -f "${WEB_DIR}/index.html" ]; then
    echo "✗ No se encuentra ${WEB_DIR}/index.html"
    echo "  ¿Estás ejecutando el script desde la raíz del repositorio?"
    exit 1
fi
echo "✓ Archivos web encontrados"

# ── Instalar dependencias npm ──────────────────────────────────────────────────
echo "⟳ Instalando dependencias (puede tardar 1-2 min la primera vez)..."
(cd "${SERVER_DIR}" && npm install --production 2>&1) | grep -E "added|warn|error|ERR" | head -10 || true
if [ ! -d "${SERVER_DIR}/node_modules" ]; then
    echo "✗ npm install falló. Revisa los errores de arriba."
    exit 1
fi
echo "✓ Dependencias instaladas"

# ── Crear carpetas de datos locales ───────────────────────────────────────────
mkdir -p "${TEST_DATA_DIR}/floorplans"
echo "✓ Carpeta de datos: ${TEST_DATA_DIR}"

# ── Variables de entorno ───────────────────────────────────────────────────────
export UI_PORT=8099
export SUPERVISOR_TOKEN=""
export HA_WORKING_DIR="${HOME}"
export HA_AUTO_LAUNCH="false"
export HA_SKIP_PERMISSIONS="false"
export HA_FONT_SIZE="14"
export HA_THEME_JSON='{"background":"#1e1e1e","foreground":"#d4d4d4","cursor":"#d4d4d4","selection":"rgba(255,255,255,0.15)","black":"#1e1e1e","red":"#f44747","green":"#608b4e","yellow":"#dcdcaa","blue":"#569cd6","magenta":"#c678dd","cyan":"#4ec9b0","white":"#d4d4d4","brightBlack":"#808080","brightRed":"#f44747","brightGreen":"#608b4e","brightYellow":"#dcdcaa","brightBlue":"#569cd6","brightMagenta":"#c678dd","brightCyan":"#4ec9b0","brightWhite":"#ffffff"}'
# Rutas locales (sobreescriben las del contenedor)
export WEB_DIR="${WEB_DIR}"
export FLOORPLANS_DIR="${TEST_DATA_DIR}/floorplans"
export LAYOUTS_FILE="${TEST_DATA_DIR}/floorplan-layouts.json"

echo ""
echo "────────────────────────────────────────────────────────"
echo "  Servidor → http://localhost:8099"
echo "  Pulsa Ctrl+C para detener"
echo "────────────────────────────────────────────────────────"
echo ""

# Limpiar al salir
cleanup() { echo ""; echo "Detenido."; }
trap cleanup EXIT INT TERM

node "${SERVER_DIR}/index.js"
