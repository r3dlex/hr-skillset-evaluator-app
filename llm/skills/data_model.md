# Skill: Data Model

## Entity Relationship Overview

```
User ──< UserTeam >── Team
 │
 ├──< Evaluation >── Skill ──< SkillGroup ──< Skillset
 │
 └──< ChatConversation ──< ChatMessage
```

## Core Schemas

### User
| Field | Type | Notes |
|-------|------|-------|
| id | integer | Primary key |
| email | string | Unique, required |
| name | string | Display name |
| role | string | "admin", "manager", or "user" |
| job_title | string | Normalized: Dev, QE, DevOps, UX, PM, PO, AI, Lead |
| location | string | Office location |
| active | boolean | Soft-delete flag |
| hashed_password | string | bcrypt hash |

### Team
| Field | Type | Notes |
|-------|------|-------|
| id | integer | Primary key |
| name | string | Unique team name |
| member_count | virtual | Computed via subquery |

### UserTeam (Join Table)
| Field | Type | Notes |
|-------|------|-------|
| user_id | integer | FK to users |
| team_id | integer | FK to teams |
| role | string | Role within team (optional) |

Users can belong to **multiple teams** (many-to-many).

### Skillset
| Field | Type | Notes |
|-------|------|-------|
| id | integer | Primary key |
| name | string | e.g., "Fullstack", "Domain" |
| description | string | |
| position | integer | Display order |
| applicable_roles | string | JSON array of role strings, empty = visible to all |
| skill_count | virtual | Count of skills via subquery |

### SkillGroup
| Field | Type | Notes |
|-------|------|-------|
| id | integer | Primary key |
| name | string | Group name within skillset |
| position | integer | Display order |
| skillset_id | integer | FK to skillsets |

### Skill
| Field | Type | Notes |
|-------|------|-------|
| id | integer | Primary key |
| name | string | Individual skill name |
| priority | string | "critical", "high", "medium", "low" |
| position | integer | Display order |
| skill_group_id | integer | FK to skill_groups |

### Evaluation
| Field | Type | Notes |
|-------|------|-------|
| id | integer | Primary key |
| user_id | integer | FK to users (the person being evaluated) |
| skill_id | integer | FK to skills |
| skillset_id | integer | FK to skillsets (denormalized for query performance) |
| period | string | "YYYY-HN" format |
| manager_score | float | 0.0 - 5.0, nullable |
| self_score | float | 0.0 - 5.0, nullable |
| evaluated_by | integer | FK to users (the evaluator), nullable |

**Unique constraint**: `[user_id, skill_id, period]` — one evaluation per user per skill per period.

### ChatConversation
| Field | Type | Notes |
|-------|------|-------|
| id | integer | Primary key |
| user_id | integer | FK to users |
| title | string | Auto-generated or user-set |
| locale | string | "en", "de", "zh" |
| message_count | integer | Counter cache |

### ChatMessage
| Field | Type | Notes |
|-------|------|-------|
| id | integer | Primary key |
| conversation_id | integer | FK to chat_conversations |
| role | string | "user", "assistant", "system" |
| content | string | Message text |
| token_usage | string | JSON: { input, output } |
| provider | string | "anthropic", "minimax" |
| model | string | Model identifier |

## Key Queries

### Team averages
Average of all manager_scores for a skill within a team, for a given period.

### Role averages
Average of all manager_scores for a skill across users with matching job_title, for a given period.

### Gap analysis
`manager_score - self_score` per skill, optionally enriched with team_avg and role_avg.

## Database

- **Engine**: SQLite via `ecto_sqlite3`
- **File**: `/app/data/skillset_evaluator.db`
- **Migrations**: Run automatically on container start
- **No raw SQL**: All queries through Ecto (ADR-001)
