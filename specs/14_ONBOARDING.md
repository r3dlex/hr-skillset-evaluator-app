# 14 — Onboarding

## Overview

Hybrid onboarding system with four layers that guide new users through the application without being intrusive.

## Architecture

### Layer 1: Rich Empty States

Every view shows actionable guidance when no data exists instead of blank screens.

| View | Empty Condition | Message | CTA |
|------|----------------|---------|-----|
| ManagerDashboard | No teams/members | "Welcome! Let's set up your team evaluation" | Import xlsx / Create skillset |
| UserDashboard | No radar data | "Your skills journey starts here" | Start self-evaluation |
| SkillsetView | No evaluations | Role-specific: evaluate (mgr) or self-eval (user) | Link to action |
| SelfEvaluationView | No skills defined | "Your manager can add skills by importing data" | — |
| SettingsView | No skillsets | "Get started by uploading your SkillMatrix.xlsx" | Import / Create |

### Layer 2: Role-based Checklist

Persistent sidebar widget tracking setup progress.

**Manager steps (5):**
1. Import skill matrix
2. Review skillsets
3. Evaluate a team member
4. View a radar chart
5. Export data

**User steps (4):**
1. View your scores
2. Complete a self-evaluation
3. View your radar chart
4. Check gap analysis

Progress stored in `users.onboarding_completed_steps` (JSON string).

### Layer 3: Tooltip Tour

Optional guided tour triggered by "Take a tour" button in the checklist.

- Pure Vue implementation (no external library)
- `useTour` composable + `TourTooltip` component
- Dark backdrop with cutout around target element
- Keyboard: Escape to close, Arrow keys to navigate
- Teleported to body, avoids z-index issues

### Layer 4: Persisted Progress

**DB columns** on `users` table:
- `onboarding_completed_steps` — JSON string array of step IDs (default `"[]"`)
- `onboarding_dismissed` — boolean (default false)

**API endpoints:**
- `GET /api/me` — includes `onboarding: {completed_steps, dismissed}`
- `PUT /api/me/onboarding` — body: `{step: "step_id"}` — marks step complete
- `DELETE /api/me/onboarding` — dismisses the checklist

## Component Structure

```
AppLayout.vue
├── TourTooltip.vue (Teleported to body)
└── Sidebar.vue
    └── OnboardingChecklist.vue
        ├── Progress bar
        ├── Step list (checkbox + label + route link)
        ├── "Take a tour" button
        └── "Dismiss" link
```

## Data Flow

```
Login → fetchMe() → auth store populates user.onboarding
  → onboarding store syncs via syncFromUser()
  → Sidebar renders OnboardingChecklist if isVisible
  → User completes action → completeStep(id) → PUT /api/me/onboarding
  → Step checks off, progress bar updates
  → All steps done → checklist auto-hides
  → Or user clicks Dismiss → DELETE /api/me/onboarding → checklist hides
```

## Test Coverage

- Backend: 16 new tests (context functions + controller endpoints)
- Frontend: 23 new tests (onboarding store + checklist component)
- Total: 84 backend + 85 frontend = 169 tests
