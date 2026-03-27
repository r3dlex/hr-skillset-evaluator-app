# 04 — REST JSON API

## Base URL

`/api`

All responses use JSON. Errors return `{"error": "message"}` with appropriate HTTP status.

## Authentication

### POST /api/auth/login
Login with email/password. Returns session cookie.
```json
// Request
{"email": "user@example.com", "password": "secret"}
// Response 200
{"user": {"id": 1, "email": "...", "name": "...", "role": "manager"}}
```

### GET /api/auth/microsoft
Redirects to Microsoft OAuth. Callback at `/api/auth/microsoft/callback`.

### DELETE /api/auth/logout
Destroys session. Returns 204.

### GET /api/me
Returns current user profile.
```json
{"id": 1, "email": "...", "name": "...", "role": "manager", "team": {"id": 1, "name": "BIM"}}
```

## Teams

### GET /api/teams
Manager only. Returns teams the manager oversees.
```json
{"teams": [{"id": 1, "name": "BIM", "member_count": 12}]}
```

### GET /api/teams/:id/members
Manager only. Returns team members with summary.
```json
{"members": [{"id": 2, "name": "Florian Haag", "role": "user", "location": "DE"}]}
```

## Skillsets & Skills

### GET /api/skillsets
Returns all skillsets with skill counts.
```json
{"skillsets": [{"id": 1, "name": "Domain", "skill_count": 44, "group_count": 6}]}
```

### GET /api/skillsets/:id
Returns skillset with groups and skills.
```json
{
  "id": 1, "name": "Domain",
  "skill_groups": [
    {
      "id": 1, "name": "ESTIMATE & QUANTIFICATION",
      "skills": [
        {"id": 1, "name": "BoQ Structure", "priority": "critical"},
        {"id": 2, "name": "Procurement", "priority": "high"}
      ]
    }
  ]
}
```

### POST /api/skillsets (Manager)
Create a skillset.
```json
// Request
{"name": "AI", "description": "AI/ML skills"}
// Response 201
{"id": 6, "name": "AI", ...}
```

### PUT /api/skillsets/:id (Manager)
Update skillset name/description.

### POST /api/skillsets/:id/skill_groups (Manager)
Add skill group to skillset.

### POST /api/skill_groups/:id/skills (Manager)
Add skill to group.

## Evaluations

### GET /api/evaluations?user_id=X&skillset_id=Y&period=Z
Returns evaluations for a user in a skillset.
```json
{
  "evaluations": [
    {
      "skill_id": 1, "skill_name": "Angular",
      "manager_score": 4, "self_score": 3,
      "evaluated_by": "Jane Manager"
    }
  ]
}
```

- Users can only query their own `user_id`
- Managers can query any user in their team

### PUT /api/evaluations (Manager)
Bulk update manager scores.
```json
// Request
{
  "user_id": 2, "period": "2025-Q1",
  "scores": [
    {"skill_id": 1, "manager_score": 4},
    {"skill_id": 2, "manager_score": 3}
  ]
}
// Response 200
{"updated": 2}
```

### PUT /api/self-evaluations (Authenticated User)
Bulk update self scores.
```json
// Request
{
  "period": "2025-Q1",
  "scores": [
    {"skill_id": 1, "self_score": 3},
    {"skill_id": 2, "self_score": 2}
  ]
}
// Response 200
{"updated": 2}
```

## Import/Export

### POST /api/import/xlsx (Manager)
Multipart upload of xlsx file. Parses and upserts evaluations.
```
Content-Type: multipart/form-data
file: <xlsx binary>
period: "2025-Q1"
```
```json
// Response 200
{"imported": {"users": 168, "evaluations": 3024, "skills_created": 0}}
```

### GET /api/export/xlsx?skillset_id=X&period=Y (Manager)
Downloads xlsx in the original format.
Returns `Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`.

## Radar Chart Data

### GET /api/radar?user_ids=1,2,3&skillset_id=1&period=2025-Q1
Returns radar-chart-ready data.
```json
{
  "axes": ["Angular", "TypeScript", "RxJS", ...],
  "series": [
    {"user_id": 1, "name": "Florian", "color": "#3b82f6", "values": [4, 5, 3, ...]},
    {"user_id": 2, "name": "Neha", "color": "#ef4444", "values": [3, 4, 2, ...]}
  ]
}
```

## Dashboard

### GET /api/dashboard/stats?team_id=X&period=Y
Returns aggregated statistics for the manager dashboard.
```json
{
  "total_skills": 115,
  "average_score": 2.8,
  "skills_rated": 3024,
  "completion_percentage": 87.5
}
```

Query params:
- `team_id` (optional) — filter stats to a specific team (uses `user_teams` join table)
- `period` (optional) — filter by evaluation period

## Periods

### GET /api/periods
Returns all distinct evaluation periods.
```json
{"periods": ["2025-Q1", "2024-Q4", "2024-Q3"]}
```

## Gap Analysis

### GET /api/gap-analysis?user_id=X&skillset_id=Y&period=Z&team_id=T&location=L
Returns manager vs self score deltas with team and role averages.
```json
{
  "skills": [
    {
      "skill_id": 1,
      "name": "Angular",
      "priority": "critical",
      "manager_score": 4,
      "self_score": 3,
      "team_avg": 3.2,
      "role_avg": 3.5,
      "gap": 1
    },
    {
      "skill_id": 2,
      "name": "TypeScript",
      "priority": "high",
      "manager_score": 5,
      "self_score": 5,
      "team_avg": 4.1,
      "role_avg": 4.3,
      "gap": 0
    }
  ]
}
```

Query params:
- `user_id` — user being analyzed
- `skillset_id` — skillset to analyze
- `period` — evaluation period
- `team_id` (optional) — team for computing team average (uses `user_teams` join table)
- `location` (optional) — filter team/role averages by user location (e.g., "DE", "IN")
