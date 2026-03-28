# Roles & Permissions

The app uses three roles with different access levels.

## Admin

Full access to all features:
- Everything a Manager can do
- Access to all teams (not just their own)
- System-wide configuration

## Manager

Team evaluation capabilities:
- View and manage their team members
- Create assessments
- Evaluate team members (manager scores)
- View radar charts for all team members
- View gap analysis with team/role averages
- Import xlsx skill matrices
- Export evaluation data
- Create and manage skillsets
- Access the AI Assistant with team-level context

## User (Team Member)

Individual evaluation access:
- View their own dashboard and scores
- Complete self-evaluations
- View their own radar charts
- View gap analysis (self vs manager, vs team/role averages)
- Access the AI Assistant for self-evaluation help

::: info Data Privacy
Users can only see their own evaluation data. The AI Assistant enforces the same access rules — it cannot reveal other users' scores or identifying information.
:::

## Role Assignment

Roles are assigned when user accounts are created (typically during xlsx import or by an administrator). Users cannot change their own role.
