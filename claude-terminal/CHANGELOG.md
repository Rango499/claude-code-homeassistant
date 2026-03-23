# Changelog

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
