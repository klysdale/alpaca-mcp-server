#!/bin/sh
set -e

# Ensure required credentials are present and not left at build-time defaults.
if [ -z "${ALPACA_API_KEY:-}" ] || [ "${ALPACA_API_KEY}" = "changeme" ]; then
  echo "Error: ALPACA_API_KEY is not set. Provide credentials via build args or environment." >&2
  exit 1
fi

if [ -z "${ALPACA_SECRET_KEY:-}" ] || [ "${ALPACA_SECRET_KEY}" = "changeme" ]; then
  echo "Error: ALPACA_SECRET_KEY is not set. Provide credentials via build args or environment." >&2
  exit 1
fi

HOST_VALUE="${HOST:-0.0.0.0}"
PORT_VALUE="${PORT:-7800}"
TRANSPORT_VALUE="${MCP_TRANSPORT:-http}"

case "${TRANSPORT_VALUE}" in
  stdio|http|sse) ;;
  *)
    echo "Error: MCP_TRANSPORT must be one of [stdio, http, sse]. Got '${TRANSPORT_VALUE}'." >&2
    exit 1
    ;;
esac

echo "Starting Alpaca MCP server on ${HOST_VALUE}:${PORT_VALUE} (transport=${TRANSPORT_VALUE})"

exec alpaca-mcp-server serve \
  --transport "${TRANSPORT_VALUE}" \
  --host "${HOST_VALUE}" \
  --port "${PORT_VALUE}"
