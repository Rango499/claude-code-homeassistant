ARG BUILD_FROM
FROM $BUILD_FROM

# ==============================================================================
# Labels
# ==============================================================================
LABEL \
    io.hass.name="Claude Code Terminal" \
    io.hass.description="Terminal integrado con Claude Code CLI para Home Assistant" \
    io.hass.type="addon" \
    io.hass.version="1.0.0"

# ==============================================================================
# Variables de entorno
# ==============================================================================
ENV LANG C.UTF-8
ENV DEBIAN_FRONTEND noninteractive
ENV NODE_VERSION 20

# ==============================================================================
# Instalar dependencias del sistema
# ==============================================================================
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        curl \
        wget \
        git \
        jq \
        vim \
        nano \
        htop \
        tree \
        python3 \
        python3-pip \
        python3-venv \
        build-essential \
        pkg-config \
        ssl-cert \
        ca-certificates \
        gnupg \
        lsb-release \
        procps \
        net-tools \
        iputils-ping \
        openssh-client \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Instalar Node.js (necesario para Claude Code)
# Descarga el binario oficial de nodejs.org para mayor compatibilidad multi-arch
# ==============================================================================
RUN NODE_VER="20.18.1" \
    && ARCH=$(uname -m) \
    && case "$ARCH" in \
        x86_64)  NODE_ARCH="x64" ;; \
        aarch64) NODE_ARCH="arm64" ;; \
        armv7l)  NODE_ARCH="armv7l" ;; \
        *)       echo "Arquitectura no soportada: $ARCH" && exit 1 ;; \
    esac \
    && wget -O /tmp/node.tar.gz \
        "https://nodejs.org/dist/v${NODE_VER}/node-v${NODE_VER}-linux-${NODE_ARCH}.tar.gz" \
    && tar -xzf /tmp/node.tar.gz -C /usr/local --strip-components=1 \
    && rm /tmp/node.tar.gz \
    && node --version && npm --version

# ==============================================================================
# Instalar Claude Code CLI
# ==============================================================================
RUN npm install -g @anthropic-ai/claude-code

# ==============================================================================
# Instalar herramientas adicionales útiles para Home Assistant
# ==============================================================================
RUN pip3 install --no-cache-dir --break-system-packages \
    pyyaml \
    requests \
    homeassistant-api \
    aiohttp \
    colorama \
    rich

# ==============================================================================
# Instalar servidor web Node.js (UI principal + editor de planos)
# ==============================================================================
WORKDIR /usr/share/claude-terminal/server
COPY server/package.json .
RUN npm install --production

# ==============================================================================
# Copiar archivos del addon
# ==============================================================================
WORKDIR /
COPY rootfs /
COPY run.sh /run.sh
COPY scripts/ /usr/share/claude-terminal/scripts/
COPY server/ /usr/share/claude-terminal/server/

RUN chmod +x /run.sh \
    && chmod +x /usr/share/claude-terminal/scripts/*.sh \
    && find /etc/s6-overlay -name "run" -exec chmod +x {} \; \
    && find /etc/s6-overlay -name "finish" -exec chmod +x {} \; 2>/dev/null || true

# ==============================================================================
# Puerto: 8099 = UI principal (editor de planos + terminal xterm.js)
# No se necesita el 7681 — el terminal PTY corre directamente en Node.js
# ==============================================================================
EXPOSE 8099

# ==============================================================================
# Healthcheck
# ==============================================================================
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:8099 || exit 1

CMD ["/run.sh"]
