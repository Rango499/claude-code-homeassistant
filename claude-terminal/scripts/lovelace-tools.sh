#!/usr/bin/env bash
# ==============================================================================
# Herramientas Lovelace para Claude Code Terminal
# Comandos para gestionar dashboards, picture-elements y tarjetas
# ==============================================================================

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; NC='\033[0m'

# ==============================================================================
# lv-floorplans: Listar planos subidos
# ==============================================================================
lv-floorplans() {
    echo -e "${CYAN}🖼️  Planos disponibles en /config/www/floorplans/${NC}"
    if [ -d "/config/www/floorplans" ]; then
        ls -lh /config/www/floorplans/ | grep -v "^total" | grep -v "^d" | \
            awk '{print "  " $NF " (" $5 ")"}'
        echo ""
        echo -e "  URL en HA: ${YELLOW}/local/floorplans/<nombre>${NC}"
    else
        echo -e "  ${RED}No hay planos. Súbelos desde el Editor de Planos en la UI.${NC}"
    fi
}

# ==============================================================================
# lv-yamls: Listar YAMLs de Lovelace generados
# ==============================================================================
lv-yamls() {
    echo -e "${CYAN}📄 YAMLs de picture-elements generados${NC}"
    ls /config/www/floorplans/*.yaml 2>/dev/null | while read f; do
        echo "  $(basename $f)"
    done || echo -e "  ${RED}No hay archivos YAML aún. Usa el Editor de Planos para generarlos.${NC}"
}

# ==============================================================================
# lv-open-editor: Abrir el editor de planos (mensaje de ayuda)
# ==============================================================================
lv-open-editor() {
    echo -e "${CYAN}🏠 Editor de Planos${NC}"
    echo ""
    echo -e "  Abre el panel ${YELLOW}Claude HA${NC} en la barra lateral de Home Assistant."
    echo -e "  Allí encontrarás el editor visual con:"
    echo ""
    echo -e "  📤 Subir un plano de la vivienda (PNG, JPG, SVG)"
    echo -e "  📍 Añadir elementos interactivos (clic en el plano)"
    echo -e "  🔧 Configurar entidades, iconos y acciones"
    echo -e "  📋 Exportar el YAML de la picture-elements card"
    echo -e "  💾 Guardar en /config/www/floorplans/"
}

# ==============================================================================
# lv-install-card: Instrucciones para instalar el YAML en Lovelace
# ==============================================================================
lv-install-card() {
    local yaml_file="${1}"
    echo -e "${CYAN}📋 Cómo instalar la tarjeta en Lovelace${NC}"
    echo ""
    if [ -n "${yaml_file}" ] && [ -f "${yaml_file}" ]; then
        echo -e "  Contenido de ${yaml_file}:"
        cat "${yaml_file}"
        echo ""
    fi
    echo -e "  ${YELLOW}Pasos:${NC}"
    echo -e "  1. Ve a tu dashboard de Lovelace"
    echo -e "  2. Haz clic en ⋮ → Editar dashboard"
    echo -e "  3. Añade una nueva tarjeta → Manual"
    echo -e "  4. Pega el YAML generado por el Editor de Planos"
    echo -e "  5. Guarda los cambios"
    echo ""
    echo -e "  ${GREEN}O bien, desde Claude Code:${NC}"
    echo -e "  Dile a Claude: 'Añade esta picture-elements card a mi dashboard'"
    echo -e "  y pega el YAML que copiaste del editor"
}

# ==============================================================================
# lv-check-www: Verificar que el directorio www está bien configurado
# ==============================================================================
lv-check-www() {
    echo -e "${CYAN}🔍 Verificando /config/www/...${NC}"
    if [ -d "/config/www" ]; then
        echo -e "  ${GREEN}✅ /config/www existe${NC}"
        echo -e "  Los archivos aquí son accesibles en HA como /local/"
        ls /config/www/ | sed 's/^/  /'
    else
        echo -e "  ${RED}❌ /config/www no existe${NC}"
        echo -e "  Creando..."
        mkdir -p /config/www/floorplans
        echo -e "  ${GREEN}✅ Creado /config/www/floorplans/${NC}"
    fi
    if [ -d "/config/www/floorplans" ]; then
        local count=$(ls /config/www/floorplans/*.{png,jpg,jpeg,gif,svg,webp} 2>/dev/null | wc -l)
        echo -e "  Planos subidos: ${YELLOW}${count}${NC}"
    fi
}

# ==============================================================================
# lv-help: Ayuda
# ==============================================================================
lv-help() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   Claude HA Terminal - Comandos Lovelace/Planos      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Gestión de planos:${NC}"
    echo -e "  ${GREEN}lv-floorplans${NC}          Lista los planos subidos"
    echo -e "  ${GREEN}lv-yamls${NC}               Lista los YAMLs generados"
    echo -e "  ${GREEN}lv-check-www${NC}           Verifica el directorio www"
    echo ""
    echo -e "${YELLOW}Lovelace:${NC}"
    echo -e "  ${GREEN}lv-install-card${NC} [f]    Instrucciones para instalar la tarjeta"
    echo -e "  ${GREEN}lv-open-editor${NC}         Cómo usar el editor visual"
    echo ""
    echo -e "${YELLOW}Editor visual:${NC}"
    echo -e "  Accede al panel ${GREEN}Claude HA${NC} en la barra lateral de HA"
    echo -e "  Pestaña '${GREEN}Editor de Planos${NC}' para subir planos y añadir elementos"
    echo -e "  Pestaña '${GREEN}Claude Terminal${NC}' para el terminal de IA"
}

export -f lv-floorplans lv-yamls lv-open-editor lv-install-card lv-check-www lv-help
