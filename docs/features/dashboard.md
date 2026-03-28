# Dashboard

The Manager Dashboard is the primary landing page for managers and admins. It provides a high-level view of your team's evaluation status and quick access to key actions.

## Overview

When you navigate to the Dashboard, you will see:

- **Stats overview cards** at the top showing key metrics such as total team members, completed evaluations, pending evaluations, and average skill score.
- **Team member list** below the cards, displaying each member with their evaluation status for the selected assessment.
- **Assessment selector** to switch between different assessment periods.
- **Role filter** to narrow the team member list by role.

## Assessment Selector

The assessment selector dropdown at the top of the dashboard lets you choose which assessment period to view. Options include:

- **Specific assessments** -- View data for a single assessment period (e.g., "Q1 2026", "Annual Review 2025").
- **All** -- Aggregates data across all assessment periods, giving you a comprehensive overview.

::: tip
Use the "All" option to get a bird's-eye view of how skills have progressed over time across multiple assessments.
:::

## Role Filter

The role filter lets you narrow the displayed team members by their assigned role. This is useful when you manage a large team with mixed roles and want to focus on a specific group (e.g., only developers, or only designers).

## Stats Overview Cards

The stats cards update dynamically based on your selected assessment and role filter. They provide at-a-glance metrics:

| Card | Description |
|---|---|
| Team Members | Total count of members matching the current filter |
| Completed | Number of members with fully completed evaluations |
| Pending | Number of members still awaiting evaluation |
| Average Score | Mean skill score across all evaluated members |

## Navigating from the Dashboard

Click on any team member row to navigate directly to their evaluation detail page. From there, you can view their radar chart, enter or update scores, and see gap analysis data.

::: info
The dashboard is only visible to users with the **manager** or **admin** role. Regular users see their own evaluation view instead.
:::
