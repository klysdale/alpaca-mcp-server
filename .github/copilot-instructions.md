## Quick orientation for AI coding agents

This repository is a multi-project monorepo containing several services (MCP server image, multiple Node APIs, and several Vite UIs). The goal of these instructions is to give you the essential, repo-specific knowledge so you can make targeted code changes without asking for the obvious details.

### Big-picture architecture (what talks to what)
- `alpaca-mcp-server/` — Python-based MCP server shipped as a Docker image. Exposes MCP over HTTP (default port 7800). See `alpaca-mcp-server/README.md` for build args and runtime examples.
- `chatbot-api/`, `markets-api/`, `groceries-api/` — Node.js Express APIs. Pattern: `src/routes` -> `src/services` -> `src/api` (provider clients). Use CommonJS modules.
- `chatbot-ui/`, `markets-ui/`, `groceries-ui/` — Vite + React frontends (TypeScript in some). Use `@/` alias for `src/` (see `tsconfig.json`).

Data flow example: UI -> chatbot-api (HTTP /api/*) -> provider client in `src/api/<provider>` -> external LLM or MCP server. The MCP server is a separate container (or process) and is contacted over HTTP by services that integrate directly with Alpaca via MCP transport.

### Project-specific conventions (do this here)
- Node APIs use CommonJS, 4-space indent, single quotes. Follow patterns in `chatbot-api/AGENTS.md` and `CLAUDE.md`.
- Provider clients live under `src/api/<provider>/index.js` and export a `sendMessage`-style function. When adding a provider, create the provider client and then wire it into `src/services/aiService` (see existing providers).
- Routes are mounted under `/api` (check `src/app.js` or `src/index.js`). Update `swagger.yaml` in that service when adding endpoints.
- Logging: use the project logger (Winston) — do not sprinkle console.log for server code.

### Common developer workflows & commands
- Run an API locally:
  - cd into the service (e.g., `chatbot-api/`) and run `npm install` then `npm run dev` (nodemon, default port 7201).
- Build/run the MCP server image (example copied from repo):
  ```bash
  docker build \
    --build-arg ALPACA_API_KEY="your-key" \
    --build-arg ALPACA_SECRET_KEY="your-secret" \
    -t alpaca-mcp-server:local .
  docker run --rm -p 7800:7800 alpaca-mcp-server:local
  ```
- Compose: Many services include a `docker-compose.yml` for dev. Use `docker compose up --build` in that service directory.

### Important environment & header patterns
- MCP image build/run args and env names: `ALPACA_API_KEY`, `ALPACA_SECRET_KEY`, `ALPACA_API_BASE_URL`, `PORT` (default 7800), `MCP_TRANSPORT` (http/sse/stdio). Do not commit real keys.
- Node APIs expect `.env` files per-service. Typical vars: `PORT`, `NODE_ENV`, DB credentials, provider API keys (named per-provider). Use `X-API-Key` or `Authorization` where existing routes expect them — check the service's README or `src/middleware/authMiddleware.js`.
- Streaming requests to the MCP server require appropriate Accept headers (both `application/json` and `text/event-stream` may be required). Use the `initialize` JSON-RPC example from `alpaca-mcp-server/README.md` to test connectivity.

### How to add a new LLM/provider (explicit actionable steps)
1. Add `src/api/<provider>/index.js` that exports a `sendMessage(payload, logger)` function. Support both single-message and `messages` array formats.
2. Add provider-specific defaults and error handling following patterns in `chatbot-api/src/api`.
3. Wire into `src/services/aiService.js` (or equivalent) — handle provider selection and normalize responses.
4. Add route-level wiring if needed (controller -> service -> provider).
5. Update `AGENTS.md` or `CLAUDE.md` for that service with a short example request payload.

### Debugging tips & quick checks
- Check container logs for MCP server: `docker logs <container>`; expected startup line: `Starting Alpaca MCP server on 0.0.0.0:7800 (transport=http)`.
- Use curl to validate MCP JSON-RPC endpoint (example in README): POST to `/mcp` with an `initialize` JSON-RPC message.
- For Node services, reproduce requests locally with `curl` or Postman and ensure `X-API-Key` header if required.
- When changing routes, update `swagger.yaml` in that service to keep API docs and tests consistent.

### Files to inspect for patterns (use these as source of truth)
- `alpaca-mcp-server/README.md` — MCP build/run, env names, healthchecks
- `chatbot-api/AGENTS.md`, `chatbot-api/CLAUDE.md` — Node API conventions and provider wiring
- `chatbot-ui/AGENTS.md` and `tsconfig.json` — Vite commands and `@/` import alias
- `swagger.yaml` files in API services — canonical API surface for integration tests

If anything above is missing or unclear, tell me which service or workflow you want expanded and I will update this file with concrete examples or add a small runbook per service.
