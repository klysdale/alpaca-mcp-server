# Alpaca MCP Server (Docker)

Containerized deployment of the official [`alpaca-mcp-server`](https://pypi.org/project/alpaca-mcp-server/)
configured for HTTP-based MCP transport with credentials baked into the image. This repository targets
scenarios where a single Alpaca account powers downstream services (such as a chatbot API) without
requiring callers to provide API keys on each request.

## Features

- Python-based MCP server using `alpaca-mcp-server serve --transport http` by default
- Docker image exposes the server on port `7800` (configurable) with JSON-RPC served at `/mcp`
- Build-time credential injection via `ARG -> ENV`, with runtime validation
- Example `docker-compose.yml` showing how to run alongside a chatbot service
- Simple TCP health check to confirm the MCP listener is up

## Repository Layout

```
.
|-- Dockerfile
|-- docker-compose.yml
|-- entrypoint.sh
`-- scripts/
    `-- healthcheck.py
```

## Requirements

- Docker 24+
- Docker Compose v2 (optional, for multi-service setups)

## Build-Time Configuration

| Build Arg              | Default                            | Description                                             |
| ---------------------- | ---------------------------------- | ------------------------------------------------------- |
| `ALPACA_API_KEY`      | `changeme` (must override)         | Alpaca API key baked into the image                     |
| `ALPACA_SECRET_KEY`   | `changeme` (must override)         | Alpaca API secret (alias: `ALPACA_API_SECRET`)          |
| `ALPACA_API_BASE_URL` | `https://paper-api.alpaca.markets` | Base URL for Alpaca endpoints                           |
| `HOST`                | `0.0.0.0`                          | Bind address for the MCP server                         |
| `PORT`                | `7800`                             | Listener port for MCP transport                         |
| `MCP_TRANSPORT`       | `http`                             | MCP transport (`stdio`, `http`, or `sse`)               |

> **Important:** The entrypoint refuses to start if `ALPACA_API_KEY` or `ALPACA_SECRET_KEY`
> remains `changeme` or empty.

### Build with baked credentials

```bash
docker build \
  --build-arg ALPACA_API_KEY="your-key" \
  --build-arg ALPACA_SECRET_KEY="your-secret" \
  --build-arg ALPACA_API_BASE_URL="https://paper-api.alpaca.markets" \
  -t alpaca-mcp-server:local .
```

Credentials provided via build arguments are copied into environment variables inside the image.
Because the values live in the final image, avoid pushing the resulting image to public registries.

## Running the Container

```bash
docker run --rm \
  -p 7800:7800 \
  alpaca-mcp-server:local
```

Environment overrides at runtime are optional but supported. For example, to change the exposed
port without rebuilding:

```bash
docker run --rm \
  -e PORT=9000 \
  -p 9000:9000 \
  alpaca-mcp-server:local
```

To switch transports (e.g., to server-sent events), set `MCP_TRANSPORT`:

```bash
docker run --rm \
  -e MCP_TRANSPORT=sse \
  -p 7800:7800 \
  alpaca-mcp-server:local
```

## Docker Compose Example

The included `docker-compose.yml` builds the image with your credentials and runs the server as a
managed service.

1. Create an `.env` file alongside `docker-compose.yml`:

   ```env
   ALPACA_API_KEY=your-key
   ALPACA_SECRET_KEY=your-secret
   # Optional overrides
   # ALPACA_API_BASE_URL=https://api.alpaca.markets
   # PORT=7800
   # MCP_TRANSPORT=http
   ```

2. Build and launch the MCP server:

   ```bash
   docker compose up --build
   ```

   The server listens on `http://localhost:${PORT:-7800}/mcp` for clients connecting from the host machine.

## Health & Diagnostics

- The image defines a Docker `HEALTHCHECK` that opens a TCP connection to the configured port.
- View container logs for startup confirmation:

  ```bash
  docker logs <container-name>
  ```

  Example log line: `Starting Alpaca MCP server on 0.0.0.0:7800 (transport=http)`

- To manually verify connectivity from the host:

  ```bash
  curl -X POST http://localhost:7800/mcp \
    -H "Content-Type: application/json" \
    -H "Accept: application/json, text/event-stream" \
    -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"1.0","capabilities":{}}}'

- When testing with Postman or curl, include both `Accept: application/json` and
  `Accept: text/event-stream` to satisfy the Streamable HTTP requirements. Without these headers the
  server returns `Not Acceptable`.
  ```

## Security Notes

- Keep the repository free of real API credentials. Pass secrets via CLI flags, `.env` files excluded
  from version control, or a secure secrets manager.
- Treat any built image as sensitive material. Anyone with the image can extract the baked-in keys.
- Logging intentionally omits credential material; avoid adding verbose/debug logs that could leak secrets.

## Updating Dependencies

To update `alpaca-mcp-server` inside the image, rebuild with the latest tag pulled from PyPI:

```bash
docker build --pull --no-cache -t alpaca-mcp-server:local .
```

## License

This project is provided as-is. Refer to Alpaca's terms of service for usage restrictions tied to
your API credentials.
