FROM python:3.12-slim

# ---- Build-time credentials (override via --build-arg or docker-compose build args) ----
ARG ALPACA_API_KEY=changeme
ARG ALPACA_SECRET_KEY=changeme
ARG ALPACA_API_BASE_URL=https://paper-api.alpaca.markets
ARG HOST=0.0.0.0
ARG PORT=7800
ARG MCP_TRANSPORT=http

# ---- Environment configuration ----
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    ALPACA_API_KEY=${ALPACA_API_KEY} \
    ALPACA_SECRET_KEY=${ALPACA_SECRET_KEY} \
    ALPACA_API_SECRET=${ALPACA_SECRET_KEY} \
    ALPACA_API_BASE_URL=${ALPACA_API_BASE_URL} \
    HOST=${HOST} \
    PORT=${PORT} \
    MCP_TRANSPORT=${MCP_TRANSPORT}

WORKDIR /app

COPY scripts /app/scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

# ---- Install server runtime ----
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir alpaca-mcp-server

# ---- Health check and runtime configuration ----
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD python /app/scripts/healthcheck.py

EXPOSE 7800

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
