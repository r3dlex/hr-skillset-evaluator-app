# 08 — Testing

## Current Status

| Layer | Tests | Coverage | Status |
|-------|-------|----------|--------|
| Backend (ExUnit) | 461 tests | 80.8% | All passing |
| Frontend (Vitest) | 445 tests | 98.3% | All passing |
| **Total** | **906 tests** | — | **0 failures** |
| E2E (Playwright) | Planned | — | Not yet implemented |

## Coverage Targets

| Layer | Target | Actual | Tool |
|-------|--------|--------|------|
| Backend (line coverage) | 80% | **80.8%** ✅ | ExUnit + excoveralls |
| Frontend (line coverage) | 90% | **98.3%** ✅ | Vitest + @vitest/coverage-v8 |
| E2E critical paths | 5 flows | Planned | Playwright |

## Backend Testing (ExUnit)

### Structure

```
backend/test/
  skillset_evaluator/
    accounts_test.exs              # User CRUD, auth, password hashing
    teams_test.exs                 # Team CRUD, member queries
    skills_test.exs                # Skillsets, groups, skills CRUD
    evaluations_test.exs           # Score upsert, radar, gap analysis, periods
    assessments_test.exs           # Assessment periods CRUD, find_or_create
    chat_test.exs                  # Conversation + Message CRUD, search, limits
    glossary_test.exs              # Glossary term lookup, multilingual
    import/
      xlsx_parser_test.exs         # Row parsing, header detection, structure
      pipeline_test.exs            # run_import/3, process_rows_sync/2
      broadway_producer_test.exs   # GenStage producer, enqueue/demand lifecycle
    llm/
      anthropic_test.exs           # stream/2, chat/2, API key config
      minimax_test.exs             # chat/2, stream/2 error, locale routing
      guardrails_test.exs          # Input/output validation, injection detection
      rate_limiter_test.exs        # Per-user rate limiting, ETS cleanup
      router_test.exs              # Provider routing by locale
      context_builder_test.exs     # System prompt assembly, screen contexts
      import_xlsx_tool_test.exs    # Tool definition, execute/2 dry-run + import
  skillset_evaluator_web/
    controllers/
      auth_controller_test.exs       # Login, logout flows
      assessment_controller_test.exs # Assessment CRUD endpoints
      chat_controller_test.exs       # Conversations, messages, upload, SSE
      evaluation_controller_test.exs # Score read/write endpoints
      me_controller_test.exs         # Current user endpoint
      skillset_controller_test.exs   # Skillset CRUD endpoints
      import_controller_test.exs     # xlsx import endpoint
      export_controller_test.exs     # xlsx export endpoint
      radar_controller_test.exs      # Radar data endpoint
      gap_analysis_controller_test.exs # Gap analysis endpoint
      dashboard_controller_test.exs  # Dashboard stats endpoint
      team_controller_test.exs       # Team endpoints
      periods_controller_test.exs    # Assessment periods endpoint
      error_json_test.exs            # Error rendering
      fallback_controller_test.exs   # SPA fallback
    plugs/
      auth_test.exs                  # Auth plug, role enforcement
  support/
    fixtures.ex              # Test data factories
    conn_case.ex             # Authenticated conn helpers
    data_case.ex             # Ecto sandbox setup
    test_llm_provider.ex     # Deterministic LLM stub
```

### Running

```bash
# In Docker
docker compose run --rm app mix test
docker compose run --rm app mix test --cover

# Locally (with Elixir installed)
cd backend && mix test --cover
```

## Frontend Testing (Vitest)

### Structure

```
frontend/src/
  api/__tests__/
    client.spec.ts           # 15 tests: get, post, 401, errors, multipart, 204
    index.spec.ts            # 31 tests: all API domain functions
    chat.spec.ts             # 11 tests: conversations, messages, upload
  components/__tests__/
    RadarChart.spec.ts       # 5 tests: SVG, axes, polygons, tooltip, empty
    GapAnalysis.spec.ts      # 6 tests: rows, names, scores, gap, sort, empty
    DataInput.spec.ts        # 5 tests: rows, badges, emit, readonly, empty
    Overview.spec.ts         # 4 tests: cards, values, zero avg, defaults
    TeamLegend.spec.ts       # 5 tests: items, colors, toggle, names, empty
    SkillsetTabs.spec.ts     # 5 tests: count, active, emit, names, empty
    ScoreSlider.spec.ts      # 7 tests: range, value, emit, disabled, enabled
    Sidebar.spec.ts          # 18 tests: links, auth, manager items, startTour
    TourTooltip.spec.ts      # 14 tests: Teleport content, navigation, steps
    XlsxUpload.spec.ts       # 15 tests: drag-drop, upload, progress, reset
    OnboardingChecklist.spec.ts # 9 tests: steps, progress, dismiss
  components/chat/__tests__/
    ChatInput.spec.ts        # 12 tests: send, enter key, multiline, upload
    ChatMessage.spec.ts      # 9 tests: user/assistant, markdown, streaming
    ChatPanel.spec.ts        # 12 tests: panel, conversation list, messages
  components/logos/__tests__/
    logos.spec.ts            # 11 tests: RibLogo, SkillForgeLogo variants
  composables/__tests__/
    useTour.spec.ts          # 15 tests: start/stop, next/prev, keyboard, empty
    useScreenContext.spec.ts # 3 tests: context building, route awareness
  layouts/__tests__/
    AppLayout.spec.ts        # 8 tests: slot, chat panel toggle, sidebar
    AuthLayout.spec.ts       # 2 tests: slot rendering
  router/__tests__/
    router.spec.ts           # 17 tests: guard logic, route definitions, actual nav
  stores/__tests__/
    auth.spec.ts             # 8 tests: state, login, logout, isManager, fetchMe
    skills.spec.ts           # 11 tests: fetchSkillsets, fetchSkillset, errors
    evaluations.spec.ts      # 14 tests: fetch, upsert, radar, gap, periods
    team.spec.ts             # 14 tests: fetchTeams, setSelectedTeam, members
    chat.spec.ts             # 26 tests: SSE streaming, conversations, messages
    onboarding.spec.ts       # 14 tests: steps, completion, dismiss
    onboarding.spec.ts       # 14 tests: steps, completion, dismiss
    theme.spec.ts            # 13 tests: dark/light toggle, persistence
  views/__tests__/
    App.spec.ts              # 2 tests: renders with RouterView
    LoginView.spec.ts        # 10 tests: form, submit, errors, redirect
    DashboardRouter.spec.ts  # 2 tests: manager vs user routing
    SkillsetView.spec.ts     # 18 tests: tabs, radar, gap, assessment, manager
    SelfEvaluationView.spec.ts # 13 tests: fetch, sliders, save, AI help
    SettingsView.spec.ts     # 6 tests: skillset CRUD, import, skill groups
```

### Running

```bash
# In Docker
docker compose run --rm app sh -c "cd /app/frontend && npm test"
docker compose run --rm app sh -c "cd /app/frontend && npm run test:coverage"

# Locally (with Node installed)
cd frontend && npx vitest run --coverage
```

## E2E Testing (Playwright)

### Critical Flows (Planned)

1. **Login flow**: Email/password login → redirects to dashboard
2. **Manager evaluation**: Select member → edit scores → save → verify radar updates
3. **Self-evaluation**: User logs in → opens self-eval → submits scores
4. **xlsx import**: Manager uploads file → preview → confirm → verify data
5. **AI chat**: Send message → receive streaming response → conversation threads

### Running

```bash
docker compose run --rm playwright npx playwright test
```

## Test/Fix Loop Protocol

1. Run all backend tests → fix failures
2. Run backend coverage → identify gaps → add tests → repeat until 80%
3. Run all frontend tests → fix failures
4. Run frontend coverage → identify gaps → add tests → repeat until 90%
5. Run `archgate check` → fix violations
6. Full suite green → commit
