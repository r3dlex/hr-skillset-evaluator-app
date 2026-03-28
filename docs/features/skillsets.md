# Skillsets & Skill Groups

Skillsets define the competency framework used to evaluate team members. Each skillset contains one or more **skill groups**, and each skill group contains individual **skills** with defined score ranges.

## Navigating Skillsets

Access skillsets from the sidebar navigation. The skillset page displays:

- A list of available skillsets (e.g., "Frontend Engineering", "Leadership", "Design")
- The ability to select a skillset to view its skill groups and individual skills

## Skill Groups as Tabs

Within a skillset, skill groups are presented as **tabs**. Each tab shows the skills belonging to that group in a structured table or card layout.

For example, a "Frontend Engineering" skillset might have tabs for:

- **Core Technologies** -- HTML, CSS, JavaScript, TypeScript
- **Frameworks** -- Vue.js, React, Angular
- **Tooling** -- Webpack, Vite, Testing frameworks
- **Soft Skills** -- Code review, mentoring, documentation

Click on a tab to view and interact with the skills in that group.

## The "All" Tab

In addition to individual skill group tabs, there is a special **"All"** tab that displays every skill across all groups in a single consolidated view. This tab offers two presentation modes:

- **Table view** -- A flat table listing all skills with their current scores, making it easy to scan and compare.
- **Gap view** -- Shows the gap between each skill's current score and the target or average, highlighting areas that need attention.

::: tip
The "All" tab is especially useful for getting a complete picture of a team member's skill profile without switching between tabs.
:::

## Skill Scores

Each skill is evaluated on a numeric scale (typically 1 to 5). Scores represent:

| Score | Level |
|---|---|
| 1 | Beginner -- basic awareness, needs guidance |
| 2 | Developing -- can perform with support |
| 3 | Competent -- works independently |
| 4 | Advanced -- guides others, deep expertise |
| 5 | Expert -- recognized authority, innovates |

## Managing Skillsets

::: warning
Only admins can create or modify skillsets and skill groups. Managers can view them and use them for evaluations but cannot alter the framework structure.
:::

Skillsets are typically set up during initial onboarding by importing an XLSX file. See [Import / Export](/features/import-export) for details on the file format.
