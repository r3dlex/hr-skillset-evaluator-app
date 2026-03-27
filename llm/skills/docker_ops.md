# Skill: Docker Operations

## Container Architecture

The application runs in Docker with a multi-stage build:

| Stage | Base Image | Purpose |
|-------|-----------|---------|
| frontend-build | node:20-alpine | Build Vue 3 SPA with Vite |
| backend-build | hexpm/elixir:1.16.2-erlang-26.2.2-alpine | Compile Elixir release |
| runtime | alpine:3.19 | Run the production release |

## Docker Compose Services

### `app` (Production)
- **Port**: 4000 (host) -> 4000 (container)
- **Volumes**:
  - `./data:/app/data` — SQLite database + xlsx files + glossary
  - `./spec:/app/spec:ro` — Specification documents (read-only)
  - `./llm:/app/llm:ro` — Agent instructions and skills (read-only)
  - `./AGENTS.md:/app/AGENTS.md:ro` — Project agent guidelines (read-only)
- **Health check**: `GET http://localhost:4000/api/health`
- **Startup**: Runs migrations, seeds, then starts Phoenix server

### `pipeline-runner` (Profile: tools)
- Python 3.12 pipeline tool
- Volume: `.:/workspace:ro` (full repo, read-only)
- Depends on `app` being healthy
- Command: `python -m pipeline_runner`

### `dev` (Profile: dev)
- Uses the backend-build stage directly
- Hot-reloading via mounted source code
- Separate dev database: `skillset_evaluator_dev.db`

## Environment Variables

### Required
| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | API key for Claude LLM |
| `SECRET_KEY_BASE` | Phoenix secret (64+ hex chars) |

### Optional
| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_PATH` | `/app/data/skillset_evaluator.db` | SQLite file path |
| `PHX_HOST` | `localhost` | Hostname for URL generation |
| `PORT` | `4000` | HTTP listen port |
| `ANTHROPIC_MODEL` | `claude-sonnet-4-20250514` | LLM model |
| `ANTHROPIC_BASE_URL` | Anthropic default | Override for proxies |
| `LLM_PROVIDER` | `anthropic` | `anthropic`, `minimax`, or `auto` |
| `LLM_MAX_TOKENS` | `4096` | Max response tokens |
| `LLM_TEMPERATURE` | `0.7` | LLM temperature |
| `CHAT_RETENTION_DAYS` | `90` | Auto-delete old conversations |

## Common Operations

```bash
# Start production
docker-compose up --build -d

# View logs
docker-compose logs -f app

# Run backend tests
docker-compose run --rm app mix test

# Access Elixir shell
docker-compose exec app bin/skillset_evaluator remote

# Rebuild after code changes
docker-compose up --build -d

# Start with dev profile (hot reload)
docker-compose --profile dev up

# Run pipeline tools
docker-compose --profile tools run --rm pipeline-runner
```

## Internal URLs

From within the Docker network:
- App: `http://app:4000`
- API: `http://app:4000/api`
- Health: `http://app:4000/api/health`

From host machine:
- App: `http://localhost:4000`
- API: `http://localhost:4000/api`

## File Paths Inside Container

```
/app/                          # Application root
/app/bin/skillset_evaluator    # Release binary
/app/priv/static/              # Frontend SPA assets
/app/data/                     # SQLite DB + data files (volume)
/app/data/glossary_aec_construction.md  # AEC glossary
/app/spec/                     # Spec documents (read-only mount)
/app/llm/                      # Agent config (read-only mount)
/app/llm/AGENTS.md             # Agent instructions
/app/llm/skills/               # Skill definitions
/app/AGENTS.md                 # Project guidelines (read-only mount)
```
