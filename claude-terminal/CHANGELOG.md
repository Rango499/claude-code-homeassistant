## [1.0.9] - 2026-03-23

### Corregido
- **Eliminado ttyd por completo** — raíz del segfault persistente en aarch64 (Raspberry Pi 4)
- Terminal PTY ahora corre directamente dentro del servidor Node.js usando `node-pty` (módulo nativo Node.js, sin binarios C externos)
- Protocolo WebSocket xterm.js simplificado: stdin/stdout directo + JSON `{type:"resize"}` (sin auth token de ttyd)
- Dockerfile limpiado: eliminadas dependencias de ttyd (`libjson-c-dev`, `libwebsockets-dev`), puerto 7681 ya no se expone
- Healthcheck apunta correctamente a puerto 8099
- Añadido `test-local.sh` en la raíz del repositorio para probar el servidor Node.js localmente antes de hacer push

## [1.0.8] - 2026-03-23

### Corregido
- Segfault de ttyd eliminado definitivamente: se quitan `--base-path /terminal` y todas las opciones `-t theme/fontSize` del comando ttyd
- Terminal reescrito con **xterm.js nativo** (sin iframe): conecta directamente al WebSocket de ttyd (`/terminal/ws → /ws`), aplica tema y tamaño de fuente desde el servidor sin depender de ttyd para ello
- Endpoint `/api/config` nuevo en el servidor Node.js para exportar el tema y el `font_size` configurados al frontend xterm.js
- Indicador de estado de conexión visible (verde = conectado, rojo = desconectado) con reconexión automática cada 3 s

## [1.0.7] - 2026-03-23

### Corregido
- Saltos de línea Windows (CRLF) en scripts de shell causaban `bash\r: No such file or directory` y segfault de ttyd
- Añadido `.gitattributes` que fuerza LF en todos los archivos de texto

# Changelog

## [1.0.6] - 2026-03-23

### Corregido
- Tema y tamaño de fuente no se aplicaban: `--theme` y `--font-size` no son flags de ttyd; sustituidos por `-t theme=...` y `-t fontSize=...` (client options)

## [1.0.5] - 2026-03-23

### Corregido
- Terminal en blanco: `bash --rcfile ... -c` no funciona como terminal interactivo; sustituido por `bash -i` con auto-launch desde `.bashrc`
- WebSocket del terminal no conectaba: añadido handler `server.on('upgrade')` en el servidor HTTP para que ttyd funcione a través del proxy
- ttyd ahora usa `--base-path /terminal` para que sus assets se sirvan correctamente bajo el proxy

## [1.0.4] - 2026-03-23

### Cambiado
- Eliminada la opción `anthropic_api_key`: la autenticación es siempre via OAuth con cuenta de Anthropic, igual que en VS Code
- Añadido banner informativo en la pestaña Terminal explicando el flujo de autenticación OAuth
- Las credenciales OAuth se guardan en `/data/claude-config/` y persisten entre reinicios

## [1.0.3] - 2026-03-23

### Añadido
- Nueva opción `anthropic_api_key` en la configuración del addon (campo password enmascarado)
- La API key se exporta automáticamente como `ANTHROPIC_API_KEY` en el terminal

### Corregido
- Tema del terminal: mapeado correcto de nombres (dark/light/solarized/monokai) a JSON de xterm.js que entiende ttyd

## [1.0.2] - 2026-03-23

### Corregido
- `server/index.js`: ruta al directorio web incorrecta dentro del contenedor (causaba `ENOENT: no such file or directory`)

## [1.0.1] - 2026-03-23

### Corregido
- `run.sh`: eliminada dependencia de `bashio` como intérprete de shebang (causaba `unable to exec bashio` en el arranque)
- La configuración del addon ahora se lee directamente desde `/data/options.json` con `jq`, que es más robusto
- Eliminadas arquitecturas `armhf` e `i386` no soportadas por Node.js 20
- Instalación de Node.js cambiada a binario oficial de nodejs.org para mayor compatibilidad multi-arch

## [1.0.0] - 2026-03-16

### Añadido
- Terminal web basado en ttyd con Claude Code CLI preinstalado
- Soporte multi-arquitectura (amd64, aarch64, armv7, armhf, i386)
- Autenticación OAuth persistente entre reinicios
- Comandos HA integrados: `ha-entities`, `ha-state`, `ha-call`, `ha-logs`, `ha-backup`, `ha-reload`, `ha-check`, `ha-restart`
- Generación automática de `CLAUDE.md` con contexto de la instalación
- Soporte para paquetes adicionales (apt y pip)
- Acceso completo a `/config`, `/share`, `/media`
- Panel integrado en el dashboard de Home Assistant
- Tema configurable (dark, light, solarized, monokai)
- Tamaño de fuente configurable
- Opción `dangerously_skip_permissions` para uso avanzado
- Directorio de trabajo configurable
- Healthcheck del contenedor
- Bashrc personalizado con alias útiles
