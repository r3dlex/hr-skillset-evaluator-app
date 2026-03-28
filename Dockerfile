# =============================================================================
# Stage 1: Build frontend assets
# =============================================================================
FROM node:20-alpine AS frontend-build

WORKDIR /app/frontend

COPY frontend/package.json ./
COPY frontend/package-lock.json* ./
RUN if [ -f package-lock.json ]; then npm ci --prefer-offline --no-audit; else npm install --no-audit; fi

COPY frontend/ ./
# Override outDir for Docker build (vite.config.ts points to ../backend/priv/static for local dev)
RUN npx vite build --outDir /app/frontend/dist

# =============================================================================
# Stage 1b: Build documentation (VitePress)
# =============================================================================
FROM node:20-alpine AS docs-build

WORKDIR /app/docs

COPY docs/package.json ./
COPY docs/package-lock.json* ./
RUN if [ -f package-lock.json ]; then npm ci --prefer-offline --no-audit; else npm install --no-audit; fi

COPY docs/ ./
RUN npx vitepress build

# =============================================================================
# Stage 2: Build Elixir release
# =============================================================================
FROM hexpm/elixir:1.16.2-erlang-26.2.2-alpine-3.19.1 AS backend-build

RUN apk add --no-cache git make gcc musl-dev

ENV MIX_ENV=prod

WORKDIR /app/backend

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install and compile deps first (layer caching)
COPY backend/mix.exs ./
COPY backend/mix.lock* ./
RUN mix deps.get --only prod && \
    mix deps.compile

# Copy backend source
COPY backend/ ./

# Copy frontend build into priv/static
COPY --from=frontend-build /app/frontend/dist ./priv/static

# Copy docs build into priv/static/docs
COPY --from=docs-build /app/docs/.vitepress/dist ./priv/static/docs

# Compile application, digest static assets, and build release
RUN mix compile && \
    mix phx.digest && \
    mix release

# =============================================================================
# Stage 3: Runtime (minimal image)
# =============================================================================
FROM alpine:3.19 AS runtime

RUN apk add --no-cache \
    libstdc++ \
    openssl \
    ncurses-libs \
    libgcc

ENV LANG=C.UTF-8 \
    MIX_ENV=prod \
    PHX_SERVER=true

WORKDIR /app

# Create non-root user
RUN addgroup -S appuser && adduser -S appuser -G appuser

# Copy release from build stage
COPY --from=backend-build /app/backend/_build/prod/rel/skillset_evaluator ./
COPY --from=backend-build /app/backend/priv/static ./priv/static

# Create data directory for SQLite
RUN mkdir -p /app/data && chown -R appuser:appuser /app

USER appuser

EXPOSE 4000

# Run migrations then start the server
CMD ["/bin/sh", "-c", "/app/bin/skillset_evaluator eval 'SkillsetEvaluator.Release.migrate()' && /app/bin/skillset_evaluator eval 'SkillsetEvaluator.Release.seed()' && /app/bin/skillset_evaluator start"]
