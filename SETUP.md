# Publicar en GitHub — Pasos exactos

## 1. Crear el repositorio en GitHub

Ve a: https://github.com/new

Rellena:
- **Repository name**: `claude-code-homeassistant`
- **Visibility**: Public  ← obligatorio para que HA lo encuentre
- **NO** marques "Add a README" ni ".gitignore" (ya los tenemos)
- Haz clic en **Create repository**

---

## 2. Publicar desde tu PC

Abre una terminal en la carpeta del proyecto y ejecuta estos comandos uno a uno:

```bash
cd "C:\Users\Samuel\Documents\claude-code-homeassistant"

git init
git branch -M main
git add .
git commit -m "feat: initial release v1.0.0 - Claude Code Terminal + Floor Plan Editor"

git remote add origin https://github.com/rango499/claude-code-homeassistant.git
git push -u origin main
```

---

## 3. Habilitar permisos para GitHub Actions (publicar imagen Docker)

Una vez que hagas el push, ve a tu repositorio en GitHub:

1. **Settings** → **Actions** → **General**
2. Baja hasta "Workflow permissions"
3. Selecciona **Read and write permissions**
4. Marca **Allow GitHub Actions to create and approve pull requests**
5. Guarda

Esto permite que el workflow publique automáticamente la imagen Docker en `ghcr.io`.

---

## 4. Lanzar el primer build

Ve a **Actions** en tu repositorio → selecciona **Build & Publish Docker Image** → **Run workflow** → **Run workflow** (botón verde).

Tardará ~10-15 minutos (compila para 3 arquitecturas en paralelo).

---

## 5. Añadir el addon a Home Assistant

Cuando el build termine, en Home Assistant:

1. **Configuración** → **Complementos** → Tienda de complementos
2. Haz clic en ⋮ (tres puntos) → **Repositorios**
3. Añade: `https://github.com/rango499/claude-code-homeassistant`
4. Busca **Claude HA** e instálalo
5. Abre el panel → ¡listo!

---

## Comandos Git del día a día

```bash
# Ver qué archivos han cambiado
git status

# Añadir todo excepto archivos concretos
git add -- . ":(exclude)archivo.md"

# Añadir todo y luego sacar archivos del staging
git add .
git reset HEAD archivo.md

# Guardar cambios
git commit -m "descripción del cambio"

# Si GitHub rechaza el push por tener cambios remotos
git pull origin main --rebase
git push

# Subir cambios normalmente
git push
```

---

## Arquitecturas soportadas

| Arquitectura | Dispositivos |
|---|---|
| `amd64` | PC/servidor x86-64, HA en VM o NUC |
| `aarch64` | Raspberry Pi 4, Pi 5, Pi 3 en 64-bit |
| `armv7` | Raspberry Pi 3 en 32-bit, Pi 2 |

> `armhf` (Pi 1/Zero) e `i386` (PC 32-bit) **no están soportados** porque Node.js 20 no tiene binarios para esas arquitecturas.

---

## Estructura del proyecto

```
claude-code-homeassistant/
├── .github/workflows/
│   ├── build.yml        ← compila y publica la imagen Docker automáticamente
│   └── validate.yml     ← valida el addon en cada PR
├── .gitignore
├── README.md
├── repository.yaml      ← lo que HA lee para mostrar el addon en la tienda
└── claude-terminal/
    ├── config.yaml      ← configuración del addon (versión, opciones, puertos...)
    ├── build.yaml       ← imagen base por arquitectura
    ├── Dockerfile       ← receta del contenedor
    ├── run.sh           ← script de arranque (lee config de /data/options.json)
    ├── icon.png         ← icono en la tienda de addons (256×256)
    ├── logo.png         ← logo en la cabecera del addon (500×200)
    ├── DOCS.md          ← documentación del addon
    ├── CHANGELOG.md     ← historial de versiones
    ├── server/          ← servidor Node.js (UI + editor de planos)
    ├── scripts/         ← herramientas HA y Lovelace para el terminal
    └── rootfs/          ← archivos que van dentro del contenedor
```
