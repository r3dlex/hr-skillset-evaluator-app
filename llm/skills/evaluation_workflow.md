# Skill: Evaluation Workflow

## Overview

Evaluations measure competency across skills using a 0-5 scale.
Two types of scores exist: **manager assessment** and **self-assessment**.

## Score Scale

| Score | Level | Description |
|-------|-------|-------------|
| 0 | None | No knowledge or experience |
| 1 | Beginner | Basic awareness, needs heavy guidance |
| 2 | Developing | Can perform with some guidance |
| 3 | Competent | Works independently on standard tasks |
| 4 | Advanced | Handles complex scenarios, mentors others |
| 5 | Expert | Industry-recognized authority, drives innovation |

## Evaluation Periods

Format: `YYYY-HN` (e.g., `2026-H1`, `2026-H2`)
- H1 = January through June
- H2 = July through December

## Manager Evaluation Workflow

1. Manager selects a **team** from the team selector
2. Manager selects a **team member** from the member list
3. Manager selects a **skillset** (e.g., Fullstack)
4. For each skill in the skillset, manager assigns a score (0-5)
5. Scores are saved immediately via `PUT /api/evaluations`
6. Manager can optionally filter by **skill group** within a skillset

### API Call
```
PUT /api/evaluations
{
  "user_id": 42,
  "skillset_id": 3,
  "skill_id": 15,
  "period": "2026-H1",
  "manager_score": 4
}
```

## Self-Assessment Workflow

1. User navigates to **Self-Evaluation** view
2. User selects a skillset
3. For each skill, user assigns their own score (0-5)
4. Self-scores are saved with `self_score` field

### API Call
```
PUT /api/evaluations
{
  "user_id": 42,
  "skillset_id": 3,
  "skill_id": 15,
  "period": "2026-H1",
  "self_score": 3
}
```

## Radar Chart

The radar chart visualizes scores as a spider/radar diagram:
- **Axes**: One per skill in the selected skillset (or skill group)
- **Series**: Manager score line, self-score line, optional team/role average lines
- **Colors**: Each series has a distinct color

### API Call
```
GET /api/radar?user_id=42&skillset_id=3&period=2026-H1
```

## Gap Analysis

Gap analysis compares manager and self scores to identify discrepancies:
- **Gap** = `manager_score - self_score`
- Positive gap: manager rates higher than self (under-confident)
- Negative gap: self rates higher than manager (over-confident)
- Optional: `team_avg` and `role_avg` for benchmarking

### API Call
```
GET /api/gap-analysis?user_id=42&skillset_id=3&period=2026-H1&include_team_avg=true&include_role_avg=true
```

## Skillset Visibility by Role

Not all skillsets are visible to all job titles:

| Skillset | Visible To |
|----------|-----------|
| Softskills | Everyone |
| Domain | Everyone |
| Fullstack | Dev, QE, DevOps, Lead |
| Product | UX, PM, PO, Lead |
| AI | AI |
| UX | UX |

Lead role sees the union of Dev + PO scopes.

## Guidance Tips for Users

When discussing evaluations with users:
- Encourage honest self-assessment — it's about growth, not performance review
- A gap between manager and self scores is normal and useful for discussion
- Suggest focusing development on **critical** and **high** priority skills first
- Team averages provide context but shouldn't be the primary benchmark
- Recommend setting concrete goals for skills scored below 3
