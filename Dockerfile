# ── Build stage: install Python deps ─────────────────────────────────────────
# Python 3.12: the SSL workaround in app/__init__.py is scoped to Windows + 3.14,
# so the container uses the system trust store with verification fully enabled.
FROM python:3.12-slim AS builder

WORKDIR /app

# System deps for grpcio (google-cloud) and gevent (needs a C compiler)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc g++ libffi-dev && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# ── Runtime stage ─────────────────────────────────────────────────────────────
FROM python:3.12-slim

WORKDIR /app

# curl is required by HEALTHCHECK below
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl && rm -rf /var/lib/apt/lists/*

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy application source (respects .dockerignore)
COPY . .

# Create uploads directory for local fallback images (inside the app package,
# where Flask now resolves static/ from)
RUN mkdir -p app/static/uploads

# Run as a non-root user — a container compromise should not get root.
RUN useradd --create-home --shell /usr/sbin/nologin stockgrid \
    && chown -R stockgrid:stockgrid /app
USER stockgrid

# Cloud Run delivers requests on port 8080
ENV PORT=8080 \
    FLASK_ENV=production \
    PYTHONUNBUFFERED=1

# Liveness probe — verifies the app answers HTTP and can reach MySQL.
# Without this a container that starts but cannot reach the DB looks healthy.
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
    CMD curl -fsS "http://127.0.0.1:${PORT}/health" || exit 1

# gevent worker class is mandatory here. The /dashboard/live SSE endpoint holds
# each connection open for its whole lifetime; with sync or threaded workers
# every open dashboard consumes a full thread and the app stops serving other
# requests after a handful of users. gevent multiplexes them as greenlets.
CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:${PORT} \
    --worker-class gevent \
    --workers 2 \
    --worker-connections 1000 \
    --timeout 120 \
    --graceful-timeout 30 \
    --access-logfile - \
    --error-logfile - \
    wsgi:app"]
