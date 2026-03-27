# HR Skillset Evaluator — Application Handout

> Version 1.0 · March 2026 · Internal Reference Document

---

## 1. Executive Summary

The HR Skillset Evaluator is an interactive web application that enables engineering organizations to track, visualize, and analyze team skill proficiency across multiple skillsets (Domain, Fullstack, UX, Product, AI, Softskills). Managers evaluate team members on a structured 0–5 proficiency scale, while employees complete self-assessments — both perspectives are surfaced together as an interactive radar/spider chart for immediate visual insight. The application replaces fragmented spreadsheet-based skill tracking by providing a single source of truth with bidirectional xlsx sync, role-based access control, and guided onboarding so teams are productive from day one.

**Target audience:** HR managers and team leads in engineering organizations who need to understand skill coverage, identify development gaps, and produce standardized skill snapshots for performance reviews.

**Key value proposition:** Replace static spreadsheets with interactive visualizations, gap analysis, and a structured evaluation workflow — while retaining full compatibility with existing SkillMatrix.xlsx files through bidirectional import/export.

---

## 2. Key Features

| Feature | Description |
|---------|-------------|
| Radar / Spider Charts | Interactive SVG charts showing skill proficiency per person, with multi-user overlay for team comparison |
| Manager Evaluations | Managers score team members on a 0–5 proficiency scale per skill, per period |
| Self-Assessments | Employees submit their own scores independently from the manager evaluation |
| Gap Analysis | Bar chart showing manager vs self scores with team average and role average comparisons, sorted by priority then gap size |
| xlsx Import/Export | Full bidirectional sync with existing SkillMatrix.xlsx files via a Broadway concurrent pipeline |
| Role-based Access | Two roles — Manager and User — with role-based skillset visibility (Dev, QE, UX, PM, PO, AI, Lead, DevOps) |
| Dashboard Stats | Manager dashboard with total skills, average score, skills rated, completion percentage, and role filter |
| Region Filter | Managers can filter team views by location (DE, IN, CN, AT, etc.) |
| Multi-team Membership | Users can belong to multiple teams via a many-to-many join table |
| Microsoft Entra ID SSO | OAuth 2.0 / OIDC login via Microsoft Entra ID (Azure AD), alongside email/password auth |
| Guided Onboarding | Four-layer system: rich empty states, role-based checklists, tooltip tour, persisted progress |

---

## 3. Architecture & Technology

### Single-Container Architecture

```
┌───────────────────────────────────────────────────────┐
│                   Docker Container                    │
│                                                       │
│  ┌─────────────────────────────────────────────────┐  │
│  │              Phoenix (port 4000)                │  │
│  │                                                 │  │
│  │   ┌──────────────────┐  ┌────────────────────┐  │  │
│  │   │   JSON REST API  │  │   Vue 3 SPA (/)    │  │  │
│  │   │   /api/*         │  │   priv/static/     │  │  │
│  │   │   12 controllers │  │   Pinia + Tailwind │  │  │
│  │   │   4 contexts     │  └────────────────────┘  │  │
│  │   └──────────────────┘                          │  │
│  │                                                 │  │
│  │   ┌─────────────────────────────────────────┐   │  │
│  │   │        Ecto + ecto_sqlite3              │   │  │
│  │   └──────────────────┬──────────────────────┘   │  │
│  └──────────────────────┼──────────────────────────┘  │
│                         │                             │
│  ┌──────────────────────▼──────────────────────────┐  │
│  │        SQLite DB  (data/ volume mount)          │  │
│  └─────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────┘

One container · One port · One DB file · No external services
```

### Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Elixir 1.16, Phoenix 1.7 (non-umbrella) |
| Database | SQLite via `ecto_sqlite3` (WAL mode, volume-mounted) |
| Frontend | Vue 3 + TypeScript (strict), Vite, Pinia, Tailwind CSS |
| Auth | `phx.gen.auth` (session-based) + Microsoft Entra ID (`ueberauth`) |
| xlsx Processing | Broadway pipeline + `xlsxir` for in-memory parsing |
| Infrastructure | Docker multi-stage build (Node → Elixir → Alpine runtime) |
| Pipeline / ADR | Python 3.12 + Poetry, `archgate/cli` for ADR enforcement |
| CI/CD | GitHub Actions (tests, build, security scan via TruffleHog) |

### Design Principles

- **KISS**: Minimal moving parts. No Redis, no message queues, no external DB servers.
- **Zero-install**: Docker is the only host dependency. Everything else runs in containers.
- **Clean Architecture**: Phoenix contexts (`Accounts`, `Teams`, `Skills`, `Evaluations`, `Import`) isolate business logic from the web layer.
- **12-Factor Config**: All sensitive values from environment variables, never hardcoded.

### Request Flow

```
Browser → Phoenix :4000
  ├── GET /          → Serve Vue SPA (priv/static/)
  └── GET /api/*     → Controller → Context → Ecto → SQLite
                                 ↓
                         JSON response → Pinia store → Vue component
```

---

## 4. Data Model

### Entity Hierarchy

```
Skillset  ──1:N──  SkillGroup  ──1:N──  Skill
                                           │
                                        N:1 (FK)
                                           │
Team  ──N:M──  User  ──1:N──  Evaluation ──┘
 (via user_teams)                 │
                            manager_score  (set by Manager)
                            self_score     (set by User)
                            period         (e.g., "2025-Q1")
```

Users can belong to **multiple teams** (e.g., Florian Haag in both BIM and TA-DE) via the `user_teams` join table.

### Proficiency Scale

| Score | Level | Description |
|-------|-------|-------------|
| 0 | None | No experience or exposure |
| 1 | Awareness | Basic awareness; could assist with guidance |
| 2 | Beginner | Can perform simple tasks with some support |
| 3 | Intermediate | Works independently; solid working knowledge |
| 4 | Advanced | Deep expertise; can mentor others |
| 5 | Expert | Go-to authority; shapes standards and decisions |

### Skillset-Role Mapping

Users see only the skillsets applicable to their `job_title`:

| Skillset | Applicable Roles |
|----------|-----------------|
| Softskills | All roles |
| Domain | All roles |
| Fullstack | Dev, QE, DevOps, Lead |
| Product | UX, PM, PO, Lead |
| AI | AI |
| UX | UX |

Lead has the union of Dev + PO scopes (sees Fullstack and Product).

### Key Schema Details

**user_teams** — Join table for many-to-many user-team membership. Unique constraint on `(user_id, team_id)`.

**evaluations** — Central fact table. One record per `(user_id, skill_id, period)`.

| Column | Type | Notes |
|--------|------|-------|
| `user_id` | integer | Person being evaluated |
| `skill_id` | integer | Skill being scored |
| `manager_score` | integer 0–5 | Set by the manager |
| `self_score` | integer 0–5 | Set by the user themselves |
| `evaluated_by_id` | integer | Manager who submitted the score |
| `period` | string | E.g., `"2025-Q1"` |
| `notes` | text | Optional free-text comments |

**Unique constraint**: `(user_id, skill_id, period)` — one evaluation record per person, per skill, per period.

### xlsx Column Mapping

| xlsx Column | Database Field |
|-------------|----------------|
| Sheet name | `skillsets.name` |
| Row 1 group headers (merged) | `skill_groups.name` |
| Row 2 priority values | `skills.priority` |
| Row 3 skill names | `skills.name` |
| Column A — Team | `teams.name` |
| Column D — Name | `users.name` |
| Score cells (0–5) | `evaluations.manager_score` |

---

## 5. User Roles & Permissions

### Capability Matrix

| Capability | Manager | User |
|------------|:-------:|:----:|
| View team members' radar charts | Yes | No |
| Set manager scores (0–5) for team | Yes | No |
| Submit self-evaluation scores | Yes (own) | Yes (own only) |
| Import xlsx bulk data | Yes | No |
| Export evaluations to xlsx | Yes | No |
| Create / edit skillsets and skills | Yes | No |
| View gap analysis (manager vs self) | Yes | Yes (own only) |
| View own radar chart | Yes | Yes |
| Manage user accounts | Yes | No |

### Authentication Methods

**Email / Password**
- Standard session-based auth via `phx.gen.auth`
- Cookie + server-side token stored in `users_tokens` table
- 60-day token expiry, CSRF protection, `SameSite=Lax` cookie policy
- Email confirmation and password reset flows included

**Microsoft Entra ID (OAuth 2.0 / OIDC)**
- Authorization Code flow with PKCE via `ueberauth` + `ueberauth_microsoft`
- First login creates a user record with `microsoft_uid`
- Subsequent logins match by `microsoft_uid` — no password stored

### Route Protection

| Route Pattern | Access Level |
|---------------|-------------|
| `/api/auth/*` | Public |
| `/api/me` | Any authenticated user |
| `GET /api/evaluations` (own) | Any authenticated user |
| `PUT /api/self-evaluations` | Authenticated user (own only) |
| `PUT /api/evaluations` (others) | Manager only |
| `/api/skillsets` (CRUD) | Manager only |
| `/api/import/*` and `/api/export/*` | Manager only |
| `/api/teams/:id/members` | Manager (own team) |

---

## 6. Visualization Design

### Radar Chart

The radar chart is the primary visualization — rendered as pure SVG in Vue (no external charting library).

```
                    Skill A
                       │
            Skill F ───┼─── Skill B
                      ╱│╲
                     ╱ │ ╲
            Skill E ───┼─── Skill C
                       │
                    Skill D

  ○ Manager score polygon  (primary blue, 30% fill)
  ● Self-assessment polygon (secondary color, 30% fill)
```

**Rendering rules:**
- One axis per skill, evenly distributed around 360 degrees
- Five concentric polygon rings representing proficiency levels 1–5
- Linear scale from center (0) to outer ring (5)
- Axis labels positioned outside the outermost ring
- Polygon vertices animate from center on initial render (300ms ease-out)

**Multi-user overlay (Manager view):**
- Each person rendered with a unique color from the 8-color palette
- 30% fill opacity with 2px stroke at full opacity
- Click legend item to toggle a user's polygon on/off
- Hover vertex: tooltip shows `{user_name}: {skill_name} = {score}`

### Gap Analysis Chart

Bar chart showing the delta between manager score and self-score per skill, enriched with team and role averages.

```
Angular      ████████░░  4 (mgr)  vs  ███████░░░  3 (self)  team: 3.2  role: 3.5  gap: +1
TypeScript   ██████████  5 (mgr)  vs  ██████████  5 (self)  team: 4.1  role: 4.3  gap:  0
RxJS         ██████░░░░  3 (mgr)  vs  ████████░░  4 (self)  team: 2.8  role: 3.0  gap: -1
```

**Four data points per skill:** manager score, self score, team average (via `user_teams`), role average (by `job_title`).

**Priority badges** per skill: critical (red), high (orange), medium (yellow), low (green).

**Color coding by gap magnitude:**
- Green  — gap = 0 (aligned)
- Yellow — gap = ±1 (small difference)
- Red    — gap ≥ ±2 (significant misalignment)

Skills are sorted by priority first, then by absolute gap (largest first).

### Dashboard Cards

| View | Cards Shown |
|------|-------------|
| Manager Dashboard | Stats cards (total skills, avg score, skills rated, completion %), role filter, member cards with job title badges |
| User Dashboard | Personal radar chart overlay, skillset progress bars, top 5 strengths and weaknesses |

---

## 7. xlsx Import/Export

### Supported Format (3-Row Header Structure)

```
Row 1: [empty, empty, empty, empty, GROUP_A ──────, GROUP_B ──────]  ← Merged cell group headers
Row 2: [empty, empty, empty, empty, Critical, High, Critical, Med ]  ← Priority per skill
Row 3: [Team,  Loc,   Role,  Name,  Skill1,  Skill2, Skill3, Skill4]  ← Column headers + skill names
Row 4+:[BIM,   DE,    Lead,  Florian Haag, 4, 3, 5, 2]               ← Person data + scores
```

Each skill sheet corresponds to one skillset (Domain, Fullstack, UX, etc.). A "Teams" sheet provides the master roster with email addresses and roles.

### Broadway Import Pipeline

```
xlsx file upload
     │
     ├─► parse_teams_sheet()  ──► Upsert teams + users  (sequential)
     │
     └─► parse() per skill sheet
               │
               └─► Task.async_stream (concurrent per person row)
                         │
                    ┌────┴──────────────────────┐
                    │  1. ensure_team            │
                    │  2. find_or_create_user    │
                    │  3. ensure_skill + group   │
                    │  4. upsert evaluation      │
                    └───────────────────────────┘
```

**Conflict resolution:**
- Users matched by `(name, team)` — creates new user with role "user" if not found
- Skills matched by `(name, skill_group)` — creates new if not found
- Evaluations upserted on `(user_id, skill_id, period)` — import overwrites `manager_score`

### Import Validation Rules

- Scores must be integers 0–5 (empty cells = `null`, not 0)
- Person rows require a name in column D
- Completely empty rows are skipped
- Unicode characters in names are preserved as-is

### Import UI Flow

1. Manager uploads file via drag-and-drop zone or file picker
2. Selects evaluation period (e.g., "2025-Q1")
3. Preview screen shows parsed row count and newly detected skills
4. Confirm triggers the Broadway pipeline with a progress bar
5. Result summary: users imported, evaluations created/updated, errors logged

### Export

Export mirrors the 3-row header format exactly — re-importing an export is **idempotent**. Manager selects skillset(s) and period, then downloads via `/api/export/xlsx`.

---

## 8. Onboarding System

### 4-Layer Hybrid Architecture

```
Layer 1: Rich Empty States
   └─ Actionable guidance instead of blank screens
      (Manager: "Import xlsx / Create skillset")
      (User: "Start self-evaluation")

Layer 2: Role-based Checklist  (persistent sidebar widget)
   └─ Progress-tracked steps stored in DB

Layer 3: Tooltip Tour  (optional, "Take a tour" button)
   └─ Pure Vue — useTour composable + TourTooltip component
      Dark backdrop with cutout · Keyboard navigable

Layer 4: Persisted Progress
   └─ users.onboarding_completed_steps (JSON array)
      users.onboarding_dismissed (boolean)
```

### Manager Checklist (5 Steps)

| # | Step | Triggers |
|---|------|---------|
| 1 | Import skill matrix | Upload SkillMatrix.xlsx |
| 2 | Review skillsets | Navigate to Settings → Skillsets |
| 3 | Evaluate a team member | Submit at least one manager score |
| 4 | View a radar chart | Open radar chart for any user |
| 5 | Export data | Download xlsx via Export button |

### User Checklist (4 Steps)

| # | Step | Triggers |
|---|------|---------|
| 1 | View your scores | Open own radar chart |
| 2 | Complete a self-evaluation | Submit self-scores for a skillset |
| 3 | View your radar chart | View manager + self overlay |
| 4 | Check gap analysis | Open gap analysis tab |

### Tooltip Tour

- Triggered by "Take a tour" button in the onboarding checklist
- Highlights key UI elements with a dark backdrop cutout
- Navigation: previous / next buttons, or keyboard arrow keys
- Escape key closes the tour at any time
- No external library — pure Vue `useTour` composable + `TourTooltip.vue` component teleported to `<body>`

### Progress API

| Endpoint | Purpose |
|----------|---------|
| `GET /api/me` | Returns `onboarding: {completed_steps, dismissed}` |
| `PUT /api/me/onboarding` | Marks a step complete `{step: "step_id"}` |
| `DELETE /api/me/onboarding` | Dismisses the checklist permanently |

Checklist auto-hides once all steps are complete. Users can also dismiss it at any time.

---

## 9. Design System

### Color Palette

**Primary**

| Token | Hex | Usage |
|-------|-----|-------|
| Primary Blue | `#3b82f6` | Buttons, links, active states |
| Primary Dark | `#1e40af` | Hover states, emphasis |
| Primary Light | `#dbeafe` | Backgrounds, badges |

**Neutral**

| Token | Hex | Usage |
|-------|-----|-------|
| Sidebar | `#1a1a2e` | Sidebar background |
| Background | `#f8f9fa` | Main content area |
| Surface | `#ffffff` | Cards, panels |
| Border | `#e2e8f0` | Card borders, dividers |
| Text Primary | `#1e293b` | Headings, body text |
| Text Secondary | `#64748b` | Labels, descriptions |

**Status**

| Token | Hex | Usage |
|-------|-----|-------|
| Success | `#22c55e` | Aligned gaps (0 delta) |
| Warning | `#f59e0b` | Small gaps (±1 point) |
| Danger | `#ef4444` | Large gaps (±2+ points) |

**Radar Chart Palette (8 colors, cycling)**

```
#3b82f6  Blue     #ef4444  Red      #22c55e  Green    #f59e0b  Amber
#8b5cf6  Violet   #06b6d4  Cyan     #f97316  Orange   #ec4899  Pink
```

### Typography

Font: **Inter** (Google Fonts or bundled) — `Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`

| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| heading-xl | 24px | 700 | Page titles |
| heading-lg | 20px | 600 | Section headers |
| heading-md | 16px | 600 | Card titles |
| body | 14px | 400 | Body text |
| body-sm | 13px | 400 | Table cells, secondary text |
| caption | 12px | 400 | Labels, badges |
| caption-xs | 11px | 500 | Radar chart axis labels |

### Layout Structure

```
┌──────────┬────────────────────────────────────────────┐
│          │  Header  (breadcrumbs · period selector    │
│ Sidebar  │           user menu · notifications)       │
│  260px   ├────────────────────────────────────────────┤
│          │                                            │
│  Logo    │  Content Area                              │
│  Nav     │  ┌──────────────────┐ ┌─────────────────┐  │
│  Teams   │  │   Radar Chart    │ │  Team Legend    │  │
│  Skills  │  │   (SVG, 600px)   │ │  (color keys)   │  │
│  Settings│  └──────────────────┘ └─────────────────┘  │
│          │  ┌────────────────────────────────────────┐ │
│ Checklist│  │   Gap Analysis / Data Table            │ │
│ (widget) │  └────────────────────────────────────────┘ │
└──────────┴────────────────────────────────────────────┘
```

### Component Tokens

| Component | Key Style |
|-----------|-----------|
| Card | `border-radius: 12px; padding: 24px; box-shadow: 0 1px 3px rgba(0,0,0,0.04)` |
| Primary Button | `bg #3b82f6; border-radius: 8px; padding: 8px 16px; font-size: 14px` |
| Secondary Button | `transparent bg; border: 1px solid #e2e8f0; color: #1e293b` |
| Input Field | `border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px` |
| Active Tab | `color: #3b82f6; border-bottom: 2px solid #3b82f6; font-weight: 600` |
| Score Slider | `200px track; 16px blue thumb; fill tracks left to thumb position` |

---

## 10. Getting Started

### Prerequisites

- Docker Desktop (or Docker Engine + Compose plugin)
- That's it — no Node.js, Elixir, or Python required on the host

### Quick Start

```bash
# 1. Clone and configure
git clone <repo-url> hr-skillset-evaluator
cd hr-skillset-evaluator
cp .env.example .env

# 2. Build and launch (first run builds all layers)
docker compose up --build

# 3. Open the application
open http://localhost:4000
```

### Default Credentials

| Field | Value |
|-------|-------|
| URL | http://localhost:4000 |
| Admin email | `admin@example.com` |
| Admin password | `admin123456` |
| Admin role | Manager |

> Change the default credentials immediately in production via `ADMIN_EMAIL` and `ADMIN_PASSWORD` env vars.

### Environment Variables

| Variable | Required | Description |
|----------|:--------:|-------------|
| `SECRET_KEY_BASE` | Prod | Phoenix secret key (min 64 chars) |
| `DATABASE_PATH` | Prod | Absolute path to SQLite DB file |
| `PHX_HOST` | Prod | Hostname for URL generation |
| `PORT` | No | Server port (default: `4000`) |
| `MICROSOFT_CLIENT_ID` | OAuth | Azure AD application client ID |
| `MICROSOFT_CLIENT_SECRET` | OAuth | Azure AD application client secret |
| `MICROSOFT_TENANT_ID` | OAuth | Azure AD tenant ID |
| `ADMIN_EMAIL` | No | Seed admin email (default: `admin@example.com`) |
| `ADMIN_PASSWORD` | No | Seed admin password (default: `admin123456`) |

### Running Tests

```bash
# Backend — 84 ExUnit tests
cd backend && mix test

# Frontend — 85 Vitest tests
cd frontend && npx vitest run

# With coverage reports
cd backend && mix test --cover
cd frontend && npx vitest run --coverage
```

---

## 11. Project Statistics

### Data Scale (from SkillMatrix.xlsx reference dataset)

| Metric | Count |
|--------|------:|
| Users | 170 |
| Teams | 23 |
| Skills (total across all skillsets) | 115 |
| Evaluations | 18,462 |
| Skillsets (Domain, Fullstack) | 2 (expandable to 6+) |

### Codebase

| Metric | Count |
|--------|------:|
| Backend tests (ExUnit) | 84 |
| Frontend tests (Vitest) | 85 |
| Total tests | 169 |
| Specification documents | 14 |
| Architecture Decision Records (ADRs) | 5 |
| Phoenix controllers | 12 |
| Phoenix contexts | 5 |
| Ecto migrations | 7 |
| Vue components | ~20 |
| Pinia stores | 4 |

### Architecture Decision Records

| ADR | Decision |
|-----|---------|
| ADR-001 | No raw SQL — all DB access through Ecto queries and changesets |
| ADR-002 | API JSON only — controllers return JSON, no server-side HTML rendering |
| ADR-003 | Component naming — Vue files use PascalCase, multi-word names required |
| ADR-004 | No secrets — all sensitive values from env vars, never hardcoded |
| ADR-005 | Typed API client — no raw `fetch()` in components or stores |

ADRs are enforced automatically by `archgate/cli` on every CI run.

### Specification Documents

| # | Document | Scope |
|---|----------|-------|
| 01 | Architecture | System topology, KISS principles, monorepo layout |
| 02 | Data Model | 8 Ecto schemas (incl. UserTeam), SQLite tables, relationships, xlsx mapping |
| 03 | Auth & Roles | Auth flows, Manager/User roles, route protection |
| 04 | API | Full REST JSON endpoint contract with request/response examples |
| 05 | Frontend | Vue component tree, Pinia stores, routing, typed API client |
| 06 | Visualization | SVG radar chart rendering, gap analysis chart, animations |
| 07 | xlsx Import/Export | Broadway pipeline architecture, sheet parsing, import/export |
| 08 | Testing | Coverage targets, test strategy, 169 total tests |
| 09 | Pipelines | archgate ADRs, pipeline runner stages, GitHub Actions |
| 10 | Troubleshooting | Common issues: SQLite, Phoenix, Vue, Docker, OAuth, xlsx |
| 11 | Learnings | Decision log (SQLite over PG, SVG over D3, non-umbrella, etc.) |
| 12 | Deployment | Docker setup, env vars, seed data, production notes |
| 13 | Design System | Color palette, typography, spacing, component styles |
| 14 | Onboarding | 4-layer hybrid onboarding, checklists, tooltip tour |

---

*HR Skillset Evaluator · One container, one port, one DB file · Built with Elixir + Phoenix + Vue 3*
