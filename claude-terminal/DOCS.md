# Claude Code Terminal - Documentación

## ¿Qué hace este addon?

Este addon integra **Claude Code CLI** directamente en tu dashboard de Home Assistant, proporcionando un terminal web completo desde el que puedes:

- Editar archivos de configuración con asistencia de IA
- Crear y modificar automatizaciones con lenguaje natural
- Depurar errores con la ayuda de Claude
- Ejecutar comandos del sistema
- Acceder a todos los archivos de tu instalación

## Instalación

### Método 1: Repositorio personalizado (recomendado)

1. Ve a **Configuración → Addons → Tienda de addons**
2. Haz clic en los tres puntos (⋮) → **Repositorios**
3. Añade la URL: `https://github.com/tuusuario/claude-code-homeassistant`
4. Busca "Claude Code Terminal" e instálalo

### Método 2: Manual (desarrollo)

1. Copia la carpeta `claude-terminal/` a `/addons/` en tu HA
2. Recarga la tienda de addons
3. Instala el addon

## Configuración

```yaml
auto_launch_claude: true        # Inicia Claude Code automáticamente al abrir el terminal
dangerously_skip_permissions: false  # ⚠️ Salta confirmaciones de Claude (usar con cuidado)
working_directory: "/config"    # Directorio de trabajo inicial
theme: "dark"                   # Tema: dark, light, solarized, monokai
font_size: 14                   # Tamaño de fuente (8-32)
extra_packages: []              # Paquetes apt adicionales a instalar
extra_pip_packages: []          # Paquetes pip adicionales
custom_claude_md: ""            # Contexto personalizado para CLAUDE.md
```

## Primer uso

1. Abre el addon desde el panel lateral (ícono 🤖)
2. La primera vez te pedirá autenticación de Anthropic (OAuth)
3. Sigue las instrucciones en pantalla para autenticarte
4. ¡Listo! Ya puedes hablar con Claude sobre tu HA

### Ejemplos de uso

```
# En el terminal, escribe:
claude

# Luego puedes pedirle cosas como:
> "Crea una automatización que encienda las luces al anochecer"
> "¿Por qué falla esta automatización?" (y pega el error)
> "Revisa mi configuration.yaml y dime si hay errores"
> "Añade un script para apagar todas las luces de la casa"
```

## Comandos HA incluidos

El addon incluye comandos de utilidad para interactuar con HA:

| Comando | Descripción |
|---------|-------------|
| `ha-entities [domain]` | Lista entidades (opcionalmente por dominio) |
| `ha-state <entity_id>` | Ver estado detallado de una entidad |
| `ha-call <domain> <service>` | Llamar a un servicio de HA |
| `ha-logs [n]` | Ver últimas N líneas de logs |
| `ha-backup [nombre]` | Crear backup antes de cambios |
| `ha-reload <what>` | Recargar sin reiniciar (automations/scripts/all) |
| `ha-check` | Validar configuración |
| `ha-restart` | Reiniciar Home Assistant |
| `ha-help` | Mostrar ayuda completa |

## Seguridad

- La autenticación de Claude se almacena en `/data/claude-config/.claude/` y **persiste** entre reinicios
- El addon tiene acceso de lectura/escritura a `/config` y `/share`
- **Siempre** usa `ha-backup` antes de hacer cambios importantes
- Con `dangerously_skip_permissions: false` (por defecto), Claude te pedirá confirmación antes de editar archivos

## Acceso al sistema de archivos

El addon puede acceder a:

| Ruta | Acceso | Descripción |
|------|--------|-------------|
| `/config` | Lectura/Escritura | Configuración de HA |
| `/share` | Lectura/Escritura | Archivos compartidos |
| `/media` | Lectura/Escritura | Archivos multimedia |
| `/ssl` | Solo lectura | Certificados SSL |
| `/addons` | Solo lectura | Otros addons |

## Solución de problemas

### El terminal no carga
- Comprueba que el puerto 7681 no esté en uso
- Revisa los logs del addon en HA

### Claude no se autentica
- Los tokens OAuth expiran - vuelve a autenticarte con `claude auth login`
- Los credenciales se guardan en `/data/claude-config/.claude/`

### No puedo editar archivos
- Verifica que el directorio esté en los `map` del config.yaml
- Comprueba permisos con `ls -la /config`
