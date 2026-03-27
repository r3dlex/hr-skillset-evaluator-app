# 02 — Data Model

## Proficiency Scale

| Score | Level | Description |
|-------|-------|-------------|
| 0 | None | No experience or exposure |
| 1 | Awareness | Basic awareness, could assist with guidance |
| 2 | Beginner | Can perform simple tasks with some support |
| 3 | Intermediate | Works independently; solid working knowledge |
| 4 | Advanced | Deep expertise; can mentor others |
| 5 | Expert | Go-to authority; shapes standards and decisions |

## Ecto Schemas

### users (via phx.gen.auth + extensions)

| Column | Type | Notes |
|--------|------|-------|
| id | integer | PK, autoincrement |
| email | string | Unique, required |
| hashed_password | string | Nullable (OAuth users may not have one) |
| role | string | "manager" or "user", default "user" |
| name | string | Display name |
| job_title | string | Original role from xlsx (e.g., "Dev", "QE", "PM", "Lead") |
| team_id | integer | FK -> teams (primary/last assigned team) |
| location | string | "DE", "IN", "CN", "AT", etc. |
| active | boolean | Default true |
| microsoft_uid | string | Nullable, for OAuth |
| confirmed_at | naive_datetime | Email confirmation |
| onboarding_completed_steps | string | JSON array of completed step IDs |
| onboarding_dismissed | boolean | Default false |
| inserted_at | naive_datetime | |
| updated_at | naive_datetime | |

### teams

| Column | Type | Notes |
|--------|------|-------|
| id | integer | PK |
| name | string | Unique (e.g., "BIM", "BoQ", "Platform Core") |
| inserted_at | naive_datetime | |
| updated_at | naive_datetime | |

### user_teams (join table for many-to-many)

| Column | Type | Notes |
|--------|------|-------|
| id | integer | PK |
| user_id | integer | FK -> users, on_delete: delete_all |
| team_id | integer | FK -> teams, on_delete: delete_all |
| inserted_at | naive_datetime | |
| updated_at | naive_datetime | |

**Unique constraint**: `(user_id, team_id)`

Users can belong to multiple teams (e.g., Florian Haag in both BIM and TA-DE).

### skillsets

| Column | Type | Notes |
|--------|------|-------|
| id | integer | PK |
| name | string | Unique (e.g., "Domain", "Fullstack", "Softskills", "Product", "AI", "UX") |
| description | string | Optional |
| position | integer | Display order |
| applicable_roles | string | JSON array of role names (empty = all roles). E.g., `["Dev","QE","DevOps","Lead"]` |
| inserted_at | naive_datetime | |
| updated_at | naive_datetime | |

**Virtual field**: `skill_count` (computed via subquery in `list_skillsets`)

### skill_groups

| Column | Type | Notes |
|--------|------|-------|
| id | integer | PK |
| name | string | E.g., "FRONTEND", "BACKEND", "ESTIMATE & QUANTIFICATION" |
| skillset_id | integer | FK -> skillsets |
| position | integer | Display order within skillset |
| inserted_at | naive_datetime | |
| updated_at | naive_datetime | |

### skills

| Column | Type | Notes |
|--------|------|-------|
| id | integer | PK |
| name | string | E.g., "Angular", "TypeScript", "BIM Coordination" |
| priority | string | "critical", "high", "medium", "low" |
| skill_group_id | integer | FK -> skill_groups |
| position | integer | Display order within group |
| inserted_at | naive_datetime | |
| updated_at | naive_datetime | |

### evaluations

| Column | Type | Notes |
|--------|------|-------|
| id | integer | PK |
| user_id | integer | FK -> users (person being evaluated) |
| skill_id | integer | FK -> skills |
| manager_score | integer | 0-5, nullable |
| self_score | integer | 0-5, nullable |
| evaluated_by_id | integer | FK -> users (manager who scored) |
| period | string | E.g., "2025-Q1" |
| notes | text | Optional comments |
| inserted_at | naive_datetime | |
| updated_at | naive_datetime | |

**Unique constraint**: `(user_id, skill_id, period)`

## Indexes

- `users.email` (unique)
- `users.team_id`
- `user_teams.(user_id, team_id)` (unique)
- `user_teams.team_id`
- `evaluations.user_id`
- `evaluations.skill_id`
- `evaluations.(user_id, skill_id, period)` (unique)
- `skills.skill_group_id`
- `skill_groups.skillset_id`

## Relationships

```
Team many_to_many Users (via user_teams)
User many_to_many Teams (via user_teams)
User belongs_to Team (primary team, via team_id)
User has_many Evaluations (as subject)
User has_many Evaluations (as evaluator, via evaluated_by_id)
Skillset has_many SkillGroups
SkillGroup has_many Skills
Skill has_many Evaluations
```

## Skillset-Role Mapping

Controlled by `skillsets.applicable_roles`. Empty list means all roles can access.

| Skillset | applicable_roles | Visible to |
|----------|-----------------|------------|
| Softskills | `[]` | All roles |
| Domain | `[]` | All roles |
| Fullstack | `["Dev","QE","DevOps","Lead"]` | Dev, QE, DevOps, Lead |
| Product | `["UX","PM","PO","Lead"]` | UX, PM, PO, Lead |
| AI | `["AI"]` | AI |
| UX | `["UX"]` | UX |

Lead has the union of Dev + PO scopes (sees Fullstack and Product).

## xlsx Mapping

| xlsx Column | DB Field |
|-------------|----------|
| Sheet name | skillsets.name |
| Row 1 group headers | skill_groups.name |
| Row 2 priorities | skills.priority (handles "🔴 Critical", "🟠 High", "🟡 Medium", "🟢 Low") |
| Row 3 skill names | skills.name |
| Column A (Team) | teams.name + user_teams association |
| Column B (Location) | users.location |
| Column C (Role) | users.role (normalized), users.job_title (original, cleaned) |
| Column D (Name) | users.name |
| Score cells (0-5) | evaluations.manager_score |

### Job Title Normalization

The import pipeline normalizes job titles from the xlsx:
- "Dev." -> "Dev"
- "developer" -> "Dev"
- "qa" -> "QE"
- Preserves: DevOps, PM, PO, UX, AI, Lead, Consulting, Apprentice
