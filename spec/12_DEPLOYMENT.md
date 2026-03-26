# 12 — Deployment

## Local Development

### Prerequisites

- Docker and docker-compose (only requirement)

### Quick Start

```bash
# Clone and start
git clone <repo-url>
cd hr-skillset-evaluator-app

# Copy env template
cp .env.example .env
# Edit .env with your Microsoft OAuth credentials (optional for local dev)

# Build and start
docker compose up --build

# Access at http://localhost:4000
```

### docker-compose.yml Services

| Service | Purpose | Port |
|---------|---------|------|
| `app` | Phoenix + Vue SPA | 4000 |
| `pipeline-runner` | CI pipeline (on-demand) | — |

### Environment Variables (.env.example)

```bash
# Application
SECRET_KEY_BASE=generate-with-mix-phx-gen-secret
DATABASE_PATH=/app/data/skillset_evaluator.db
PHX_HOST=localhost
PORT=4000

# Microsoft OAuth (optional for local dev)
MICROSOFT_CLIENT_ID=
MICROSOFT_CLIENT_SECRET=
MICROSOFT_TENANT_ID=

# Default admin (seeded on first run)
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=change-me-in-production
```

### Data Persistence

- SQLite DB: stored in `data/` directory (Docker volume mount)
- xlsx files: place in `data/` for import via UI
- Both survive container restarts via volume mount

## Dockerfile (Multi-stage)

```
Stage 1: frontend-build (node:20-alpine)
  - npm ci (or npm install if no lock file)
  - npx vite build --outDir /app/frontend/dist
  - Output: built static files

Stage 2: backend-build (hexpm/elixir:1.16.2-erlang-26.2.2-alpine-3.19.1)
  - mix deps.get --only prod + mix deps.compile
  - Copy frontend dist into priv/static
  - mix compile + mix release
  - Output: OTP release

Stage 3: runtime (alpine:3.19)
  - Erlang runtime only (libstdc++, openssl, ncurses-libs)
  - Non-root user (appuser)
  - CMD: run migrations then start server
  - Expose port 4000
```

The build is fully reproducible -- no host dependencies. Lock files (`mix.lock`, `package-lock.json`) are committed and used in CI.

## Production Considerations

- Set `SECRET_KEY_BASE` to a strong random value
- Set `PHX_HOST` to actual domain
- Mount `data/` as a persistent volume
- Back up SQLite DB file regularly (it's just a file)
- Consider read replicas via Litestream for HA (future)
- Put behind reverse proxy (nginx/caddy) for TLS termination

## Seed Data

On first boot, the app:
1. Runs pending migrations
2. Seeds a default admin user from `ADMIN_EMAIL` / `ADMIN_PASSWORD` env vars
3. Admin can then import xlsx or create skillsets via UI
