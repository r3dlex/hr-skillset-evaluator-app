# 10 — Troubleshooting

## SQLite

### "database is locked"
- Ensure WAL mode is enabled: `PRAGMA journal_mode=WAL;`
- Check for long-running transactions blocking writes
- Configured in `config/runtime.exs`: `pragma: [journal_mode: :wal]`

### "SQLITE_BUSY"
- Set busy_timeout in Ecto config: `busy_timeout: 5000`
- Only one write transaction at a time; reads are concurrent with WAL

### Database file not found
- Ensure `/data` volume is mounted in docker-compose
- Check `DATABASE_PATH` env var points to correct location

## Phoenix / Elixir

### Mix deps won't compile
- `docker compose run --rm app mix deps.clean --all && mix deps.get`
- Check Elixir version matches `.tool-versions` / Dockerfile

### Migrations fail
- `docker compose run --rm app mix ecto.reset` (destroys data)
- Check migration files for SQLite-incompatible syntax (no arrays, no enums)

### Static assets not served
- Verify `frontend/` build output lands in `backend/priv/static/`
- Check `Plug.Static` config in `endpoint.ex`
- Run `docker compose run --rm app sh -c "cd /app/frontend && npm run build"`

## Vue / Frontend

### HMR not working in Docker
- Not applicable — frontend is built at image build time
- For dev iteration, use: `docker compose run --rm -p 5173:5173 app sh -c "cd /app/frontend && npm run dev"`

### TypeScript errors
- `npx vue-tsc --noEmit` to check
- Ensure `tsconfig.json` includes all source dirs

### Vite build fails
- Check `vite.config.ts` outDir points to `../backend/priv/static`
- Clear `frontend/node_modules/.vite` cache

## OAuth (Microsoft)

### Callback URL mismatch
- Azure portal redirect URI must match: `http://localhost:4000/api/auth/microsoft/callback`
- For production: update to actual domain

### "invalid_client"
- Verify `MICROSOFT_CLIENT_ID` and `MICROSOFT_CLIENT_SECRET` env vars
- Check tenant ID is correct

## xlsx Import

### "unable to parse xlsx"
- Verify file is actual xlsx (not xls or csv renamed)
- Check `xlsxir` can handle the file: `Xlsxir.multi_extract(path)`

### Missing scores after import
- Check column mapping: skill columns start at E (column 5)
- Verify row 3 has skill names (not empty)
- Check person name matches Teams sheet

## Docker

### Container won't start
- `docker compose logs app` for error output
- Ensure port 4000 is not in use: `lsof -i :4000`

### Build cache issues
- `docker compose build --no-cache app`

### Volume permissions
- SQLite needs write access: check data/ directory permissions in container

## AI Chat / LLM

### "ANTHROPIC_API_KEY is not set"
- Chat feature is optional -- set `ANTHROPIC_API_KEY` in `.env` to enable
- Without it, the chat FAB still appears but shows "AI chat is not configured"

### Rate limited (429)
- Per-user limits: 30 (user), 60 (manager), 120 (admin) messages per hour
- Check ETS table state or wait for the hourly reset

### SSE stream hangs
- Check network tab for the `/api/chat/conversations/:id/messages` request
- Verify the Anthropic API key is valid and has credits
- Check Phoenix logs for LLM client errors

### Chat context too large
- Token budget: ~4,000 tokens for user context
- Managers with 30+ members get summarized aggregates
- Reduce by scoping to specific skill groups or periods
