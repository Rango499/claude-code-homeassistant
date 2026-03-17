# Changelog

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
