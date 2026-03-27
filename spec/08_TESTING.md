# 08 — Testing

## Current Status

| Layer | Tests | Status |
|-------|-------|--------|
| Backend (ExUnit) | 84 tests | All passing |
| Frontend (Vitest) | 85 tests | All passing |
| Total | 169 tests | All passing |
| E2E (Playwright) | Planned | Not yet implemented |

## Coverage Targets

| Layer | Target | Tool |
|-------|--------|------|
| Backend contexts | 80% | ExUnit + excoveralls |
| Backend controllers | 75% | ExUnit |
| Frontend components | 70% | Vitest + Vue Test Utils |
| Frontend stores | 80% | Vitest |
| E2E critical paths | 5 flows | Playwright |

## Backend Testing (ExUnit)

### Structure

```
backend/test/
  skillset_evaluator/
    accounts_test.exs        # User CRUD, auth, password hashing
    teams_test.exs           # Team CRUD, member queries
    skills_test.exs          # Skillsets, groups, skills CRUD
    evaluations_test.exs     # Score upsert, radar data, gap analysis
  skillset_evaluator_web/
    controllers/
      auth_controller_test.exs       # Login, logout flows
      evaluation_controller_test.exs # Score read/write endpoints
      me_controller_test.exs         # Current user endpoint
      skillset_controller_test.exs   # Skillset CRUD endpoints
    plugs/
      auth_test.exs                  # Auth plug, role enforcement
  skillset_evaluator/
    chat_test.exs                    # Chat context: conversations, messages CRUD
    glossary_test.exs                # Glossary term lookup, multilingual
    llm/
      guardrails_test.exs            # Input/output validation
      rate_limiter_test.exs          # Per-user rate limiting
  support/
    fixtures.ex              # Test data factories
    conn_case.ex             # Authenticated conn helpers
    data_case.ex             # Ecto sandbox setup
```

### Test Data

Fixtures derived from `SkillMatrix.xlsx` structure:
- 3 teams (BIM, BoQ, Platform)
- 5 users (2 managers, 3 users)
- 2 skillsets with 3 skills each
- Sample evaluations

### Running

```bash
# In Docker
docker compose run --rm app mix test
docker compose run --rm app mix test --cover
```

## Frontend Testing (Vitest)

### Structure

```
frontend/src/
  components/__tests__/
    RadarChart.spec.ts       # 5 tests: SVG, axes, polygons, tooltip, empty
    GapAnalysis.spec.ts      # 6 tests: rows, names, scores, gap, sort, empty
    DataInput.spec.ts        # 5 tests: rows, badges, emit, readonly, empty
    Overview.spec.ts         # 4 tests: cards, values, zero avg, defaults
    TeamLegend.spec.ts       # 5 tests: items, colors, toggle, names, empty
    SkillsetTabs.spec.ts     # 5 tests: count, active, emit, names, empty
    ScoreSlider.spec.ts      # 7 tests: range, value, emit, disabled, enabled, styles
  stores/__tests__/
    auth.spec.ts             # 8 tests: state, login, logout, isManager, fetchMe, errors
    skills.spec.ts           # 5 tests: state, fetchSkillsets, fetchSkillset, errors
    evaluations.spec.ts      # 6 tests: state, fetch, radar, gap, errors
  api/__tests__/
    client.spec.ts           # 6 tests: get, post, 401 redirect, errors, non-JSON, 204
```

### Key Test Cases (85 total)

- RadarChart renders SVG with correct axes count and polygon count
- GapAnalysis sorts by absolute gap magnitude, handles null scores
- DataInput emits `update:score` on slider change, respects readonly
- ScoreSlider 0-5 range, disabled state, value display
- Auth store handles full login/logout lifecycle + error states
- API client handles 401 redirect, non-2xx errors, multipart uploads
- Chat store handles SSE streaming, conversation CRUD, message sending
- Onboarding store tracks step completion and dismissal

### Running

```bash
docker compose run --rm app sh -c "cd /app/frontend && npm test"
docker compose run --rm app sh -c "cd /app/frontend && npm run test:coverage"
```

## E2E Testing (Playwright)

### Critical Flows

1. **Login flow**: Email/password login → redirects to dashboard
2. **Manager evaluation**: Select member → edit scores → save → verify radar updates
3. **Self-evaluation**: User logs in → opens self-eval → submits scores
4. **xlsx import**: Manager uploads file → preview → confirm → verify data
5. **Radar chart interaction**: Select multiple members → verify overlaid polygons

### Running

```bash
docker compose run --rm playwright npx playwright test
```

## Test/Fix Loop Protocol

1. Run all backend tests → fix failures
2. Run backend coverage → identify gaps → add tests → repeat until 80%
3. Run all frontend tests → fix failures
4. Run frontend coverage → identify gaps → add tests → repeat until 70%
5. Run E2E tests → fix failures
6. Run `archgate check` → fix violations
7. Full suite green → commit
