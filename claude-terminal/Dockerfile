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
        cmake \
        libjson-c-dev \
        libwebsockets-dev \
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
# ==============================================================================
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g npm@latest \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Instalar ttyd (terminal web)
# ==============================================================================
RUN TTYD_VERSION=$(curl -s https://api.github.com/repos/tsl0922/ttyd/releases/latest | jq -r .tag_name) \
    && ARCH=$(uname -m) \
    && case "$ARCH" in \
        x86_64)  TTYD_ARCH="x86_64" ;; \
        aarch64) TTYD_ARCH="aarch64" ;; \
        armv7l)  TTYD_ARCH="arm" ;; \
        armhf)   TTYD_ARCH="arm" ;; \
        i686)    TTYD_ARCH="i686" ;; \
        *)       TTYD_ARCH="x86_64" ;; \
    esac \
    && wget -O /usr/local/bin/ttyd \
        "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.${TTYD_ARCH}" \
    && chmod +x /usr/local/bin/ttyd

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
# Puertos: 8099 = UI principal (editor + terminal embed), 7681 = ttyd interno
# ==============================================================================
EXPOSE 8099 7681

# ==============================================================================
# Healthcheck
# ==============================================================================
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:7681 || exit 1

CMD ["/run.sh"]
