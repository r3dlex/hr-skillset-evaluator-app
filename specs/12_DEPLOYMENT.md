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
Stage 1: frontend-build
  - Node 20 Alpine
  - npm ci + npm run build
  - Output: built static files

Stage 2: backend-build
  - Elixir 1.16 Alpine
  - mix deps.get + mix release
  - Copy frontend build into priv/static
  - Output: compiled release

Stage 3: runtime
  - Erlang runtime only (no build tools)
  - Copy release from stage 2
  - Expose port 4000
  - CMD: run migrations + start server
```

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
