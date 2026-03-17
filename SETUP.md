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

Tardará ~10-15 minutos (compila para 5 arquitecturas en paralelo).

---

## 5. Añadir el addon a Home Assistant

Cuando el build termine, en Home Assistant:

1. **Configuración** → **Complementos** → Tienda de complementos
2. Haz clic en ⋮ (tres puntos) → **Repositorios**
3. Añade: `https://github.com/rango499/claude-code-homeassistant`
4. Busca **Claude HA** e instálalo
5. Abre el panel → ¡listo!

---

## Estructura del proyecto publicado

```
claude-code-homeassistant/
├── .github/workflows/
│   ├── build.yml        ← compila y publica la imagen Docker automáticamente
│   └── validate.yml     ← valida el addon en cada PR
├── .gitignore
├── README.md
├── repository.yaml      ← lo que HA lee para mostrar el addon en la tienda
└── claude-terminal/
    ├── config.yaml      ← configuración del addon
    ├── Dockerfile       ← imagen del contenedor
    ├── run.sh           ← arranque del addon
    ├── icon.png         ← icono (256x256)
    ├── logo.png         ← logo (500x200)
    ├── server/          ← servidor Node.js (UI + editor de planos)
    ├── scripts/         ← herramientas HA y Lovelace para el terminal
    └── rootfs/          ← archivos que van dentro del contenedor
```
