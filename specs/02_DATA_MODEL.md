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
| team_id | integer | FK -> teams |
| location | string | "DE", "IN", etc. |
| active | boolean | Default true |
| microsoft_uid | string | Nullable, for OAuth |
| confirmed_at | naive_datetime | Email confirmation |
| inserted_at | naive_datetime | |
| updated_at | naive_datetime | |

### teams

| Column | Type | Notes |
|--------|------|-------|
| id | integer | PK |
| name | string | Unique (e.g., "BIM", "BoQ", "Platform") |
| inserted_at | naive_datetime | |
| updated_at | naive_datetime | |

### skillsets

| Column | Type | Notes |
|--------|------|-------|
| id | integer | PK |
| name | string | Unique (e.g., "Domain", "Fullstack", "UX") |
| description | string | Optional |
| position | integer | Display order |
| inserted_at | naive_datetime | |
| updated_at | naive_datetime | |

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
| priority | string | "critical", "high", "medium" |
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
- `evaluations.user_id`
- `evaluations.skill_id`
- `evaluations.(user_id, skill_id, period)` (unique)
- `skills.skill_group_id`
- `skill_groups.skillset_id`

## Relationships

```
Team has_many Users
User belongs_to Team
User has_many Evaluations (as subject)
User has_many Evaluations (as evaluator, via evaluated_by_id)
Skillset has_many SkillGroups
SkillGroup has_many Skills
Skill has_many Evaluations
```

## xlsx Mapping

| xlsx Column | DB Field |
|-------------|----------|
| Sheet name | skillsets.name |
| Row 1 group headers | skill_groups.name |
| Row 2 priorities | skills.priority |
| Row 3 skill names | skills.name |
| Column A (Team) | teams.name |
| Column B (Location) | users.location |
| Column C (Role) | users.role (mapped) |
| Column D (Name) | users.name |
| Score cells (0-5) | evaluations.manager_score |
