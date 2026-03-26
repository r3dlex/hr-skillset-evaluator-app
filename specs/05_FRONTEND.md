# 05 — Frontend

## Stack

- **Vue 3** with Composition API (`<script setup lang="ts">`)
- **TypeScript** (strict mode)
- **Vite** for build tooling
- **Pinia** for state management
- **Vue Router** for client-side routing
- **Tailwind CSS** for styling (see `13_DESIGN_SYSTEM.md`)

## Build Output

Vite configured to output to `../backend/priv/static/` for local dev. In Docker, the Dockerfile overrides with `--outDir /app/frontend/dist`.

```typescript
// vite.config.ts
export default defineConfig({
  build: {
    outDir: resolve(__dirname, '../backend/priv/static'),
    emptyOutDir: true,
  },
  server: {
    proxy: { '/api': { target: 'http://localhost:4000', changeOrigin: true } },
  },
})
```

## Component Tree

```
App.vue
├── layouts/
│   ├── AuthLayout.vue          # Login/register pages
│   └── AppLayout.vue           # Sidebar + main content
│       ├── Sidebar.vue         # Navigation, user info, skillset tabs
│       └── <router-view>
├── views/
│   ├── LoginView.vue           # Email/password + Microsoft SSO button
│   ├── ManagerDashboard.vue    # Team overview, member selector
│   ├── UserDashboard.vue       # Own evaluations, self-assessment
│   ├── SkillsetView.vue        # Radar chart + data table for a skillset
│   └── SettingsView.vue        # Skillset/skill management (manager only)
├── components/
│   ├── RadarChart.vue          # SVG radar/spider chart
│   ├── TeamLegend.vue          # Color-coded team member list
│   ├── DataInput.vue           # Score editor (slider/number input grid)
│   ├── GapAnalysis.vue         # Bar chart: manager vs self delta
│   ├── Overview.vue            # Summary cards, aggregated stats
│   ├── SkillsetTabs.vue        # Tab bar for switching skillsets
│   ├── XlsxUpload.vue          # Drag-and-drop xlsx import
│   └── ProjectExamplesModal.vue # Modal for project examples
```

## Routing

```typescript
const routes = [
  { path: '/login', component: LoginView, meta: { public: true } },
  { path: '/', redirect: '/dashboard' },
  { path: '/dashboard', component: () => /* dynamic based on role */ },
  { path: '/skillsets/:id', component: SkillsetView },
  { path: '/self-evaluation/:skillsetId', component: SelfEvaluationView },
  { path: '/settings/skillsets', component: SettingsView, meta: { role: 'manager' } },
]
```

## Pinia Stores

### authStore
- `user` — current user object
- `isManager` — computed from role
- `login(email, password)` / `logout()` / `fetchMe()`

### skillsStore
- `skillsets` — list of all skillsets
- `currentSkillset` — selected skillset with groups and skills
- `fetchSkillsets()` / `fetchSkillset(id)`

### evaluationsStore
- `evaluations` — current user/skillset evaluations
- `radarData` — chart-ready data
- `gapAnalysis` — gap analysis data
- `fetchEvaluations(userId, skillsetId, period)`
- `updateManagerScores(userId, scores)`
- `updateSelfScores(scores)`

### teamStore (manager only)
- `teams` / `members`
- `selectedMembers` — for radar chart overlay
- `fetchTeams()` / `fetchMembers(teamId)`

## API Client

Typed API client using `fetch` (no external HTTP lib):

```typescript
// api/client.ts
async function apiGet<T>(path: string): Promise<T> { ... }
async function apiPost<T>(path: string, body: unknown): Promise<T> { ... }
async function apiPut<T>(path: string, body: unknown): Promise<T> { ... }
```

## Key Interactions

1. **Manager selects team members** → radar chart overlays multiple polygons
2. **Manager clicks skill cell** → inline edit with 0-5 slider
3. **User opens self-evaluation** → grid of skills with 0-5 input
4. **Manager uploads xlsx** → progress indicator, then refresh
5. **Tab switching** → loads different skillset radar chart
6. **Hover on radar axis** → tooltip with skill name + scores
