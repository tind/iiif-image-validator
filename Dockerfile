# Set up base
FROM debian:13-slim AS base

WORKDIR /app

RUN <<EOF
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get --yes install --no-install-recommends \
    python3 \
    python3-venv \
    python3-dev \
    python3-legacy-cgi \
    libxml2 \
    libxslt1.1 \
    libjpeg62-turbo \
    libmagic1

apt-get clean
rm -rf /var/lib/apt/lists/*
EOF

RUN <<EOF
groupadd -g 150 appuser
useradd -u 150 -g 150 -s /sbin/nologin appuser
EOF

# Build stage
FROM base AS builder

RUN <<EOF
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get --yes install --no-install-recommends \
build-essential \
libxml2-dev \
libxslt1-dev \
libjpeg-dev \
libmagic-dev

apt-get clean
rm -rf /var/lib/apt/lists/*
EOF

COPY requirements.txt .

RUN <<EOF
python3 -m venv /opt/venv
/opt/venv/bin/pip install --no-cache-dir -r requirements.txt
chown -R appuser:appuser /opt/venv
EOF

# Runtime stage
FROM base

LABEL org.opencontainers.image.source=https://github.com/tind/iiif-image-validator

COPY --from=builder --chown=appuser:appuser /opt/venv /opt/venv
COPY --chown=appuser:appuser . .

EXPOSE 8000

USER appuser

ENTRYPOINT ["/app/docker-files/entrypoint"]

CMD ["--master", "--processes", "4", "--threads", "2"]
