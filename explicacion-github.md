# Explicación completa: GitHub y el proyecto Claude HA

## ¿Qué es GitHub y para qué lo usamos aquí?

GitHub es una plataforma donde se guardan proyectos de código. Funciona como un "Google Drive para código", pero con superpoderes: guarda el historial completo de todos los cambios, permite colaborar con otras personas, y puede ejecutar tareas automáticas (como compilar y publicar nuestro addon).

En nuestro caso lo usamos por dos razones:
1. **Home Assistant necesita un repositorio público en GitHub** para poder instalar addons de terceros
2. **Queremos que la imagen Docker se compile automáticamente** cada vez que hagamos un cambio

---

## Conceptos clave que has usado

### Git vs GitHub

Son dos cosas distintas aunque trabajan juntas:

- **Git** es el programa instalado en tu PC. Es el que ejecutas con comandos como `git add`, `git commit`, `git push`. Lleva el control de todos los cambios en tu carpeta local.
- **GitHub** es el sitio web (github.com) donde se sube y almacena el código. Es el "servidor remoto" al que Git envía los archivos.

La relación es: Git en tu PC ↔ GitHub en internet.

---

### Los comandos de Git que ejecutaste

```bash
git init
```
Convierte la carpeta `claude-code-homeassistant` en un "repositorio Git". Crea una carpeta oculta `.git` donde Git guarda todo el historial. Solo se hace una vez al principio.

```bash
git branch -M main
```
Renombra la rama principal de `master` a `main`. GitHub usa `main` por defecto desde 2020, así que los sincronizamos para que no haya conflictos.

```bash
git add .
```
Le dice a Git: "quiero incluir todos los archivos modificados en el próximo guardado". El `.` significa "todo". Los archivos quedan en un estado llamado *staging* (preparados para guardar).

```bash
git commit -m "feat: initial release v1.0.0"
```
Hace el "guardado oficial" con un mensaje descriptivo. Un commit es como una foto del estado del proyecto en ese momento. El mensaje describe qué cambió y por qué. Si en el futuro algo se rompe, puedes volver a cualquier commit anterior.

```bash
git remote add origin https://github.com/Rango499/claude-code-homeassistant.git
```
Le dice a Git dónde está el repositorio remoto (GitHub). `origin` es simplemente el nombre que le damos a esa dirección — es una convención, podría llamarse de otra forma. Solo se hace una vez.

```bash
git push -u origin main
```
Envía todos los commits locales a GitHub. El `-u` establece que de ahora en adelante, cuando hagas `git push` a secas, sepa que tiene que ir a `origin/main`. Después del primer push, los siguientes son simplemente `git push`.

---

## La estructura del repositorio explicada

```
claude-code-homeassistant/
│
├── .github/                  ← Carpeta especial que GitHub reconoce automáticamente
│   └── workflows/
│       ├── build.yml         ← Automatización: compila y publica la imagen Docker
│       └── validate.yml      ← Automatización: comprueba que el addon es válido
│
├── .gitignore                ← Lista de archivos que Git debe ignorar (node_modules, secretos...)
│
├── repository.yaml           ← Lo que Home Assistant lee para mostrar el addon en su tienda
├── README.md                 ← Descripción del proyecto (la portada del repositorio en GitHub)
│
└── claude-terminal/          ← El addon en sí
    ├── config.yaml           ← Configuración del addon (nombre, versión, opciones, puertos...)
    ├── build.yaml            ← Con qué imagen base construir para cada arquitectura
    ├── Dockerfile            ← Receta para construir el contenedor Docker
    ├── run.sh                ← Script que se ejecuta al arrancar el addon
    ├── icon.png              ← Icono que aparece en la tienda de addons de HA (256x256)
    ├── logo.png              ← Logo que aparece en la cabecera del addon (500x200)
    ├── DOCS.md               ← Documentación del addon
    ├── CHANGELOG.md          ← Historial de versiones
    ├── server/               ← Servidor Node.js (la interfaz web del addon)
    ├── scripts/              ← Herramientas de terminal (ha-tools, lovelace-tools)
    └── rootfs/               ← Archivos que se copian dentro del contenedor
```

---

## ¿Qué es Docker y por qué lo necesitamos?

Home Assistant funciona con **contenedores Docker**. Un contenedor es como una caja sellada que contiene el programa y todo lo que necesita para funcionar: el sistema operativo base, Node.js, Claude Code CLI, ttyd (el terminal web), etc. No importa qué ordenador use el usuario — la caja siempre funciona igual.

El **Dockerfile** es la receta para construir esa caja. Le dice a Docker paso a paso:
1. Empieza desde esta imagen base (Debian)
2. Instala estas dependencias del sistema
3. Descarga e instala Node.js 20
4. Instala Claude Code CLI
5. Instala ttyd
6. Copia los archivos del proyecto
7. Expón el puerto 8099

---

## ¿Qué es GitHub Actions?

GitHub Actions es el sistema de automatización de GitHub. Cuando subes código, GitHub puede ejecutar tareas automáticamente. Estas tareas se definen en archivos `.yml` dentro de `.github/workflows/`.

### Nuestro workflow `build.yml`

Se ejecuta automáticamente cada vez que haces `git push` a la rama `main`. Lo que hace:

1. **Descarga el código** del repositorio
2. **Se autentica** en el registro de imágenes Docker de GitHub (ghcr.io)
3. **Configura QEMU** — una herramienta que permite compilar para otras arquitecturas (por ejemplo, compilar código para Raspberry Pi desde un servidor x86)
4. **Compila la imagen Docker** para cada arquitectura:
   - `amd64` → ordenadores normales y servidores x86
   - `aarch64` → Raspberry Pi 4, Pi 5
   - `armv7` → Raspberry Pi 3
5. **Publica la imagen** en `ghcr.io/rango499/ha-claude-code-terminal-{arch}:latest`
6. **Crea un Release** en GitHub con el número de versión del addon

### Nuestro workflow `validate.yml`

Se ejecuta en cada Pull Request y en cada push. Comprueba que:
- El `config.yaml` del addon tiene la estructura correcta que espera HA
- El `Dockerfile` sigue buenas prácticas
- Existen todos los archivos obligatorios (icon.png, logo.png, DOCS.md...)

---

## ¿Qué es ghcr.io?

`ghcr.io` (GitHub Container Registry) es el almacén de imágenes Docker de GitHub. Es donde se guardan las imágenes compiladas. Cuando Home Assistant instala nuestro addon, va a `ghcr.io` a descargar la imagen correspondiente a la arquitectura del dispositivo del usuario.

La imagen se publica con este formato:
```
ghcr.io/rango499/ha-claude-code-terminal-amd64:1.0.0
ghcr.io/rango499/ha-claude-code-terminal-aarch64:1.0.0
ghcr.io/rango499/ha-claude-code-terminal-armv7:1.0.0
```

---

## ¿Qué es `repository.yaml`?

Es el archivo que Home Assistant lee cuando añades la URL del repositorio en la tienda de addons. Le dice a HA:
- El nombre del repositorio
- La descripción
- Qué addons contiene y dónde están

Sin este archivo, HA no reconocería el repositorio como una fuente de addons válida.

---

## El error que tuvimos y cómo lo resolvimos

El primer build falló porque usábamos el script de **NodeSource** para instalar Node.js, que no tiene versiones para `armhf` (ARMv6, Raspberry Pi 1/Zero) ni `i386` (PC 32-bit). Son arquitecturas muy antiguas que nadie usa ya en HA.

La solución fue doble:
1. **Cambiar la instalación de Node.js**: en lugar del script de NodeSource, descargamos el binario oficial directamente desde `nodejs.org`, que funciona perfectamente en las 3 arquitecturas que nos importan
2. **Eliminar armhf e i386** del build matrix, ya que son obsoletas y Node.js 20 no las soporta

---

## Flujo completo desde tu PC hasta Home Assistant

```
Tu PC (código)
    │
    │  git add . && git commit && git push
    ▼
GitHub (repositorio)
    │
    │  GitHub Actions detecta el push automáticamente
    ▼
GitHub Actions (compilación)
    │  Compila Dockerfile para amd64 + aarch64 + armv7
    ▼
ghcr.io (imágenes Docker publicadas)
    │
    │  El usuario añade el repo a HA y lo instala
    ▼
Home Assistant (descarga la imagen correcta para su hardware)
    │
    ▼
Addon funcionando: interfaz web en puerto 8099
  ├── Pestaña "Editor de Planos" → sube plano, añade entidades, exporta YAML
  └── Pestaña "Claude Terminal" → terminal con Claude Code CLI
```

---

## Para el día a día: ¿cómo actualizar el addon?

Cada vez que quieras cambiar algo (corregir un bug, añadir una función), el proceso es siempre el mismo:

```bash
# 1. Editar los archivos que necesites
# 2. Guardar los cambios en Git
git add .
git commit -m "descripción de lo que cambiaste"

# 3. Subir a GitHub (dispara el build automático)
git push
```

GitHub Actions se encarga del resto: compila, publica la imagen nueva, y crea el release. Los usuarios de HA verán la actualización disponible automáticamente.
