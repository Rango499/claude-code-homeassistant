# Claude Code Terminal para Home Assistant

Un addon para Home Assistant que integra **Claude Code CLI** directamente en tu dashboard, similar a la extensión de VS Code pero dentro de tu instalación de HA.

## ¿Qué hace?

- 🤖 **Terminal con IA**: Claude Code CLI preinstalado y listo para usar
- 📁 **Acceso completo al sistema**: Lee y escribe todos los archivos de configuración
- 🏠 **Contexto de HA**: Claude conoce tu instalación automáticamente (entidades, versión, estructura)
- 🔧 **Comandos HA**: Comandos shell para interactuar con la API de HA
- 💾 **Auth persistente**: Las credenciales de Anthropic se guardan entre reinicios
- 🎨 **Personalizable**: Temas, fuente, paquetes adicionales


## Mejoras sobre los proyectos existentes

- ✅ Comandos HA integrados (`ha-entities`, `ha-call`, `ha-backup`, etc.)
- ✅ CLAUDE.md generado automáticamente con contexto real de tu instalación
- ✅ Bash personalizado con alias y bienvenida informativa
- ✅ Soporte multi-arquitectura desde el inicio
- ✅ Paquetes adicionales configurables (apt + pip)
- ✅ Healthcheck del contenedor
- ✅ Acceso a `/share` y `/media` además de `/config`

## Instalación rápida

1. Añade este repositorio en HA: Configuración → Addons → ⋮ → Repositorios
2. Instala "Claude Code Terminal"
3. Abre el panel y autentícate con tu cuenta de Anthropic

## Estructura del proyecto

```
claude-code-homeassistant/
├── repository.yaml                    # Config del repositorio HA
├── README.md                          # Este archivo
└── claude-terminal/                   # El addon
    ├── config.yaml                    # Configuración del addon
    ├── build.yaml                     # Configuración de build
    ├── Dockerfile                     # Imagen del contenedor
    ├── run.sh                         # Script de arranque
    ├── DOCS.md                        # Documentación completa
    ├── CHANGELOG.md                   # Historial de cambios
    ├── scripts/
    │   ├── setup-claude-md.sh         # Generador de CLAUDE.md
    │   └── ha-tools.sh                # Comandos HA para el terminal
    └── rootfs/
        └── usr/share/claude-terminal/
            └── bashrc                 # Configuración del shell
```

## Licencia

MIT
