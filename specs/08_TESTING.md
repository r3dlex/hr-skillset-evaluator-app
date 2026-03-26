# 08 — Testing

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
    accounts_test.exs        # User CRUD, auth
    teams_test.exs           # Team management
    skills_test.exs          # Skillsets, groups, skills CRUD
    evaluations_test.exs     # Score management, gap analysis
    xlsx_import_test.exs     # Import parsing and upsert
    xlsx_export_test.exs     # Export generation
  skillset_evaluator_web/
    controllers/
      auth_controller_test.exs
      skillset_controller_test.exs
      evaluation_controller_test.exs
      import_controller_test.exs
      radar_controller_test.exs
    plugs/
      require_role_test.exs
  support/
    fixtures.ex              # Test data factories
    conn_case.ex
    data_case.ex
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
    RadarChart.spec.ts
    GapAnalysis.spec.ts
    DataInput.spec.ts
    TeamLegend.spec.ts
    Overview.spec.ts
  stores/__tests__/
    auth.spec.ts
    skills.spec.ts
    evaluations.spec.ts
  api/__tests__/
    client.spec.ts
  views/__tests__/
    LoginView.spec.ts
```

### Key Test Cases

- RadarChart renders correct number of axes
- RadarChart polygon points match score values
- GapAnalysis sorts by gap magnitude
- DataInput emits score updates on slider change
- Auth store handles login/logout flow
- API client handles 401 → redirect to login

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
