#!/usr/bin/env bash
# ==============================================================================
# Configura el archivo CLAUDE.md con contexto específico de Home Assistant
# Este archivo le da a Claude Code toda la información que necesita sobre tu HA
# ==============================================================================

WORKING_DIR="${1:-/config}"
CUSTOM_CONTENT="${2:-}"
CLAUDE_MD_PATH="${WORKING_DIR}/CLAUDE.md"

# Si ya existe un CLAUDE.md personalizado, respetarlo
if [ -f "${CLAUDE_MD_PATH}" ] && [ "$(wc -l < "${CLAUDE_MD_PATH}")" -gt 5 ]; then
    echo "CLAUDE.md ya existe en ${WORKING_DIR}, respetando el existente."
    exit 0
fi

# Obtener información del sistema Home Assistant via API
HA_URL="http://supervisor/core"
HA_TOKEN="${SUPERVISOR_TOKEN}"

# Intentar obtener información del sistema
HA_VERSION=$(curl -s -H "Authorization: Bearer ${HA_TOKEN}" \
    "${HA_URL}/api/config" 2>/dev/null | jq -r '.version // "desconocida"' 2>/dev/null || echo "desconocida")

HA_LOCATION=$(curl -s -H "Authorization: Bearer ${HA_TOKEN}" \
    "${HA_URL}/api/config" 2>/dev/null | jq -r '.location_name // "Mi Casa"' 2>/dev/null || echo "Mi Casa")

# Contar entidades
ENTITY_COUNT=$(curl -s -H "Authorization: Bearer ${HA_TOKEN}" \
    "${HA_URL}/api/states" 2>/dev/null | jq 'length // 0' 2>/dev/null || echo "0")

cat > "${CLAUDE_MD_PATH}" << EOF
# Claude Code - Contexto Home Assistant

## Sistema
- **Ubicación**: ${CLAUDE_MD_PATH}
- **Home Assistant versión**: ${HA_VERSION}
- **Nombre del sistema**: ${HA_LOCATION}
- **Entidades activas**: ${ENTITY_COUNT}

## Estructura de archivos importante

\`\`\`
/config/
├── configuration.yaml      # Configuración principal
├── automations.yaml        # Automatizaciones
├── scripts.yaml            # Scripts
├── scenes.yaml             # Escenas
├── groups.yaml             # Grupos
├── customize.yaml          # Personalizaciones
├── secrets.yaml            # Secretos (NO editar sin confirmar)
├── ui-lovelace.yaml        # Dashboard (si existe)
├── www/                    # Archivos web estáticos
├── custom_components/      # Integraciones personalizadas
├── blueprints/             # Blueprints de automatizaciones
└── .storage/               # Estado interno (cuidado al editar)
\`\`\`

## Reglas importantes

1. **SIEMPRE** hacer backup antes de editar configuration.yaml
2. **NUNCA** editar secrets.yaml directamente - pedir confirmación al usuario
3. **SIEMPRE** validar la sintaxis YAML antes de guardar
4. Al crear automatizaciones, usar \`automation:\` en automations.yaml
5. Al referenciar entidades, usar el formato \`domain.entity_id\`
6. Los IDs únicos de automatizaciones son obligatorios (usar formato snake_case)

## Comandos útiles

\`\`\`bash
# Verificar configuración de Home Assistant
ha core check

# Reiniciar Home Assistant
ha core restart

# Ver logs
ha core logs

# Recargar automatizaciones (sin reiniciar)
# Usar el servicio: homeassistant.reload_config_entry

# Ver estado de addons
ha addons list
\`\`\`

## API de Home Assistant

La API está disponible en: \`http://supervisor/core/api/\`
Token de autenticación: Variable de entorno \`SUPERVISOR_TOKEN\`

\`\`\`bash
# Ejemplo: listar todas las entidades
curl -s -H "Authorization: Bearer \$SUPERVISOR_TOKEN" http://supervisor/core/api/states

# Ejemplo: llamar a un servicio
curl -s -X POST \\
  -H "Authorization: Bearer \$SUPERVISOR_TOKEN" \\
  -H "Content-Type: application/json" \\
  -d '{"entity_id": "light.salon"}' \\
  http://supervisor/core/api/services/light/turn_on
\`\`\`

## Patrones YAML comunes

### Automatización básica
\`\`\`yaml
- id: 'mi_automatizacion_001'
  alias: 'Nombre descriptivo'
  description: 'Descripción de qué hace'
  trigger:
    - platform: state
      entity_id: binary_sensor.mi_sensor
      to: 'on'
  condition: []
  action:
    - service: light.turn_on
      target:
        entity_id: light.mi_luz
  mode: single
\`\`\`

### Script básico
\`\`\`yaml
mi_script:
  alias: 'Nombre del script'
  sequence:
    - service: notify.mobile_app
      data:
        message: 'Hola desde Home Assistant'
\`\`\`

${CUSTOM_CONTENT}

---
*Este archivo fue generado automáticamente por el addon Claude Code Terminal*
*Puedes editarlo para añadir contexto específico de tu instalación*
EOF

echo "CLAUDE.md creado en ${CLAUDE_MD_PATH}"
