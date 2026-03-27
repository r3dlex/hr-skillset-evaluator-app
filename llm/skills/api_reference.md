# Skill: API Reference

The application exposes a REST JSON API at `http://localhost:4000/api`.
All endpoints require session-based authentication (cookie `_session`).

## Authentication

```
POST /api/auth/login        { email, password }  -> { user }
DELETE /api/auth/logout      -> { message }
GET  /api/me                -> { user } (current user profile)
```

## Teams

```
GET  /api/teams             -> { data: [Team] }
GET  /api/teams/:id         -> { data: Team }
GET  /api/teams/:id/members -> { data: [User] }
```

## Skillsets & Skills

```
GET  /api/skillsets                  -> { data: [Skillset] }
GET  /api/skillsets/:id              -> { data: Skillset with skill_groups and skills }
POST /api/skillsets                  -> { data: Skillset }  (admin only)
PUT  /api/skillsets/:id              -> { data: Skillset }  (admin only)
```

## Evaluations

```
GET  /api/evaluations?user_id=&skillset_id=&period=&skill_group_id=
     -> { data: [Evaluation] }
PUT  /api/evaluations
     { user_id, skillset_id, skill_id, period, manager_score?, self_score? }
     -> { data: Evaluation }
```

- `manager_score` and `self_score` range from 0 to 5 (float).
- `period` format: "YYYY-HN" (e.g., "2026-H1").
- `skill_group_id` is optional — filters to skills within that group.

## Radar Data

```
GET  /api/radar?user_id=&skillset_id=&period=&skill_group_id=
     -> { axes: [string], series: [{ user_id, name, color, values }] }
```

## Gap Analysis

```
GET  /api/gap-analysis?user_id=&skillset_id=&period=&skill_group_id=&include_team_avg=&include_role_avg=
     -> { data: [{ name, skill_id, priority, manager_score, self_score, gap, team_avg?, role_avg? }] }
```

## Dashboard Statistics

```
GET  /api/dashboard/stats   -> { data: { total_users, total_teams, ... } }  (admin/manager)
```

## Chat / AI Assistant

```
GET    /api/chat/conversations              -> { data: [Conversation] }
GET    /api/chat/conversations?q=search     -> { data: [SearchResult] }
POST   /api/chat/conversations              -> { data: Conversation }
GET    /api/chat/conversations/:id          -> { data: Conversation with messages }
DELETE /api/chat/conversations/:id          -> { message }
POST   /api/chat/conversations/:id/messages -> SSE stream (event: delta/done/error)
```

## Import

```
POST /api/import/xlsx  (multipart: file, period)  -> { data: ImportSummary }
```

## Data Types

```typescript
User     { id, email, name, role, job_title, team, location, active }
Team     { id, name, member_count }
Skillset { id, name, description, position, skill_count, skill_groups, applicable_roles }
Skill    { id, name, priority, position }
Evaluation { skill_id, skill_name, manager_score, self_score }
```

## Docker Network

- **App container**: `http://app:4000` (internal), `http://localhost:4000` (host)
- **Database**: SQLite at `/app/data/skillset_evaluator.db` (volume-mounted)
- **Health check**: `GET /api/health`
