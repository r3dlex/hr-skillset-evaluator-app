# 03 — Authentication & Roles

## Authentication Methods

### 1. Email/Password (phx.gen.auth)

- Standard Phoenix-generated authentication
- Session-based (cookie + server-side token)
- Email confirmation flow
- Password reset flow

### 2. Microsoft Entra ID (OAuth 2.0 / OIDC)

- Library: `ueberauth` + `ueberauth_microsoft`
- Flow: Authorization Code with PKCE
- On first OAuth login, creates user record with `microsoft_uid`
- On subsequent logins, matches by `microsoft_uid`
- No password stored for OAuth-only users

### Configuration (env vars, never committed)

```
MICROSOFT_CLIENT_ID=<from Azure portal>
MICROSOFT_CLIENT_SECRET=<from Azure portal>
MICROSOFT_TENANT_ID=<your tenant>
```

## Roles

### Admin

- Inherits all Manager capabilities
- Can view ALL teams, ALL users, ALL evaluations (cross-team visibility)
- Can ask aggregate questions about the entire organization via AI chat
- First seeded user gets admin role
- Can configure LLM settings
- 120 chat messages per hour (vs 60 for Manager, 30 for User)

### Manager

- Can view all team members assigned to their team(s)
- Can create/edit evaluations (manager_score) for their team members
- Can import xlsx to bulk-create/update evaluations
- Can create/edit skillsets, skill groups, and skills via UI
- Can export evaluations to xlsx
- Can view radar charts for any team member in their team(s)
- Can view gap analysis (manager_score vs self_score)

### User

- Can view own evaluations (read-only, set by manager)
- Can submit/edit self-evaluations (self_score) for any skillset available to their role
- Can view own radar chart (manager + self overlay)
- Cannot view other users' data
- Cannot modify skillsets or skills

## Authorization

Implemented as Phoenix Plugs:

```elixir
# In router.ex
pipeline :require_manager do
  plug :require_role, :manager
end

pipeline :require_authenticated do
  plug :require_authenticated_user
end
```

### Route Protection

| Route Pattern | Access |
|---------------|--------|
| `/api/auth/*` | Public |
| `/api/me` | Authenticated |
| `/api/evaluations` (GET own) | Authenticated |
| `/api/self-evaluations` (PUT) | Authenticated (user) |
| `/api/evaluations` (PUT others) | Manager only |
| `/api/skillsets` (CRUD) | Manager only |
| `/api/import/*` | Manager only |
| `/api/export/*` | Manager only |
| `/api/teams/:id/members` | Manager (own team) |
| `/api/chat/conversations` | Authenticated |
| `/api/chat/conversations/:id/messages` | Owner only (SSE stream) |

## Session Management

- Phoenix session tokens stored in `users_tokens` table
- Token expiry: 60 days
- CSRF protection on all state-changing requests
- SameSite=Lax cookie policy
