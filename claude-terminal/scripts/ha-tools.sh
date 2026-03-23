#!/usr/bin/env bash
# ==============================================================================
# Herramientas de Home Assistant para usar desde Claude Code Terminal
# Añade estos comandos al PATH para usarlos directamente en el terminal
# ==============================================================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

HA_API="http://supervisor/core/api"
AUTH_HEADER="Authorization: Bearer ${SUPERVISOR_TOKEN}"

# ==============================================================================
# ha-entities: Listar entidades
# ==============================================================================
ha-entities() {
    local domain="${1:-}"
    local filter="${2:-}"

    echo -e "${CYAN}📦 Entidades de Home Assistant${NC}"

    if [ -n "${domain}" ]; then
        curl -s -H "${AUTH_HEADER}" "${HA_API}/states" | \
            jq -r ".[] | select(.entity_id | startswith(\"${domain}.\")) | \
            \"  \(.entity_id) → \(.state) (\(.attributes.friendly_name // \"sin nombre\"))\"" | \
            sort
    else
        curl -s -H "${AUTH_HEADER}" "${HA_API}/states" | \
            jq -r '.[] | "  \(.entity_id) → \(.state)"' | sort
    fi
}

# ==============================================================================
# ha-state: Ver estado de una entidad
# ==============================================================================
ha-state() {
    local entity_id="${1}"
    if [ -z "${entity_id}" ]; then
        echo -e "${RED}❌ Uso: ha-state <entity_id>${NC}"
        return 1
    fi

    echo -e "${CYAN}🔍 Estado de ${entity_id}${NC}"
    curl -s -H "${AUTH_HEADER}" "${HA_API}/states/${entity_id}" | jq '.'
}

# ==============================================================================
# ha-call: Llamar a un servicio de HA
# ==============================================================================
ha-call() {
    local domain="${1}"
    local service="${2}"
    local data="${3:-{}}"

    if [ -z "${domain}" ] || [ -z "${service}" ]; then
        echo -e "${RED}❌ Uso: ha-call <domain> <service> [data_json]${NC}"
        echo -e "  Ejemplo: ha-call light turn_on '{\"entity_id\": \"light.salon\"}'"
        return 1
    fi

    echo -e "${CYAN}⚡ Llamando ${domain}.${service}${NC}"
    local result=$(curl -s -X POST \
        -H "${AUTH_HEADER}" \
        -H "Content-Type: application/json" \
        -d "${data}" \
        "${HA_API}/services/${domain}/${service}")

    echo "${result}" | jq '.'
    echo -e "${GREEN}✅ Servicio ejecutado${NC}"
}

# ==============================================================================
# ha-logs: Ver logs de Home Assistant
# ==============================================================================
ha-logs() {
    local lines="${1:-50}"
    echo -e "${CYAN}📋 Últimas ${lines} líneas de logs${NC}"
    curl -s -H "${AUTH_HEADER}" "${HA_API}/error_log" | tail -n "${lines}"
}

# ==============================================================================
# ha-backup: Crear un backup antes de hacer cambios
# ==============================================================================
ha-backup() {
    local name="${1:-claude-backup-$(date +%Y%m%d-%H%M%S)}"
    echo -e "${YELLOW}💾 Creando backup: ${name}${NC}"

    curl -s -X POST \
        -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"${name}\"}" \
        "http://supervisor/backups/new/full" | jq '.'

    echo -e "${GREEN}✅ Backup iniciado: ${name}${NC}"
}

# ==============================================================================
# ha-reload: Recargar configuración sin reiniciar
# ==============================================================================
ha-reload() {
    local what="${1:-automations}"
    echo -e "${CYAN}🔄 Recargando: ${what}${NC}"

    case "${what}" in
        automations|automation)
            curl -s -X POST -H "${AUTH_HEADER}" "${HA_API}/services/automation/reload" > /dev/null
            ;;
        scripts|script)
            curl -s -X POST -H "${AUTH_HEADER}" "${HA_API}/services/script/reload" > /dev/null
            ;;
        scenes|scene)
            curl -s -X POST -H "${AUTH_HEADER}" "${HA_API}/services/scene/reload" > /dev/null
            ;;
        groups|group)
            curl -s -X POST -H "${AUTH_HEADER}" "${HA_API}/services/group/reload" > /dev/null
            ;;
        all)
            curl -s -X POST -H "${AUTH_HEADER}" "${HA_API}/services/homeassistant/reload_all" > /dev/null
            ;;
        *)
            echo -e "${RED}❌ Opciones: automations, scripts, scenes, groups, all${NC}"
            return 1
            ;;
    esac

    echo -e "${GREEN}✅ ${what} recargado correctamente${NC}"
}

# ==============================================================================
# ha-check: Validar la configuración de HA
# ==============================================================================
ha-check() {
    echo -e "${CYAN}🔍 Validando configuración de Home Assistant...${NC}"
    ha core check && echo -e "${GREEN}✅ Configuración válida${NC}" || \
        echo -e "${RED}❌ Errores en la configuración${NC}"
}

# ==============================================================================
# ha-restart: Reiniciar Home Assistant
# ==============================================================================
ha-restart() {
    echo -e "${YELLOW}⚠️  ¿Seguro que quieres reiniciar Home Assistant? (y/N)${NC}"
    read -r confirm
    if [ "${confirm}" = "y" ] || [ "${confirm}" = "Y" ]; then
        echo -e "${CYAN}🔄 Reiniciando Home Assistant...${NC}"
        ha core restart
    else
        echo -e "${BLUE}❌ Reinicio cancelado${NC}"
    fi
}

# ==============================================================================
# ha-help: Mostrar ayuda
# ==============================================================================
ha-help() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          Claude Code Terminal - Comandos Home Assistant       ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Comandos disponibles:${NC}"
    echo -e "  ${GREEN}ha-entities${NC} [domain]          Lista entidades (opcionalmente filtra por domain)"
    echo -e "  ${GREEN}ha-state${NC} <entity_id>          Ver estado detallado de una entidad"
    echo -e "  ${GREEN}ha-call${NC} <domain> <service>    Llamar a un servicio de HA"
    echo -e "  ${GREEN}ha-logs${NC} [lineas]              Ver logs de Home Assistant"
    echo -e "  ${GREEN}ha-backup${NC} [nombre]            Crear un backup completo"
    echo -e "  ${GREEN}ha-reload${NC} <what>              Recargar sin reiniciar (automations/scripts/all)"
    echo -e "  ${GREEN}ha-check${NC}                      Validar la configuración"
    echo -e "  ${GREEN}ha-restart${NC}                    Reiniciar Home Assistant"
    echo ""
    echo -e "${YELLOW}Ejemplos:${NC}"
    echo -e "  ha-entities light"
    echo -e "  ha-state light.salon"
    echo -e "  ha-call light turn_on '{\"entity_id\": \"light.salon\"}'"
    echo -e "  ha-reload automations"
    echo ""
    echo -e "${CYAN}También puedes usar Claude Code directamente:${NC}"
    echo -e "  claude → Inicia Claude Code interactivo"
    echo -e "  claude --help → Ver opciones de Claude Code"
}

# Exportar todas las funciones
export -f ha-entities ha-state ha-call ha-logs ha-backup ha-reload ha-check ha-restart ha-help

# Mostrar bienvenida al cargar el archivo
echo -e "${CYAN}🏠 Herramientas de Home Assistant cargadas${NC} - escribe ${GREEN}ha-help${NC} para ver comandos"
