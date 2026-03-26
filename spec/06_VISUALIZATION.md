# 06 — Visualization

## Radar Chart

### Structure (SVG-based)

The radar chart is the core visualization. Rendered as pure SVG in Vue, no external charting library.

```
┌──────────────────────────────────┐
│         Skill Name               │
│           ╱    ╲                 │
│     Skill/      \Skill           │
│       ╱   ┌──────┐╲             │
│      /   ╱ ╲    ╱ ╲ \           │
│  Skill──┤  ●──●  ├──Skill       │
│      \   ╲ ╱    ╲ ╱ /           │
│       ╲   └──────┘╱             │
│     Skill\      /Skill           │
│           ╲    ╱                 │
│         Skill Name               │
└──────────────────────────────────┘
```

### Rendering Rules

- **Axes**: One axis per skill in the selected skillset. Evenly distributed around 360 degrees.
- **Rings**: 5 concentric polygons (one per proficiency level 1-5). Light gray stroke, very faint fill.
- **Data polygons**: One polygon per selected user. Semi-transparent fill with colored stroke.
- **Axis labels**: Skill names at the end of each axis, rotated to avoid overlap.
- **Center**: Origin point (score 0).
- **Scale**: Linear from center (0) to outer ring (5).

### Interactivity

- **Hover on polygon vertex**: Tooltip showing `{user_name}: {skill_name} = {score}`
- **Click on legend item**: Toggle user visibility on chart
- **Hover on axis label**: Highlight the axis line

### Multi-user Overlay

When a manager selects multiple team members, each person's polygon is drawn with:
- Unique color from the palette (see Design System)
- 30% fill opacity
- 2px stroke at full opacity

### Responsive Sizing

- Chart container: 100% width of content area, max 600px
- SVG viewBox: `0 0 600 600` (square)
- Labels positioned outside the outermost ring

## Gap Analysis Chart

### Structure (Horizontal Bar Chart)

Displays the delta between `manager_score` and `self_score` per skill.

```
Angular          ████████░░  4 (mgr) vs ███████░░░ 3 (self)  gap: +1
TypeScript       ██████████  5 (mgr) vs ██████████ 5 (self)  gap:  0
RxJS             ██████░░░░  3 (mgr) vs ████████░░ 4 (self)  gap: -1
```

### Rendering Rules

- Two bars per skill: manager (primary color) and self (secondary color)
- Gap value shown at the end: positive = manager rated higher, negative = self rated higher
- Skills sorted by absolute gap (largest first)
- Color coding: green gap = aligned, yellow = small gap (1), red = large gap (2+)

## Overview Dashboard

### Manager View

- **Team summary cards**: One card per team showing member count + average proficiency
- **Skill coverage heatmap**: Grid showing how many team members have score >= 3 per skill
- **Top gaps**: List of skills with largest average gap across team

### User View

- **Personal radar chart**: Own manager + self evaluation overlay
- **Skillset progress**: Bar showing % of skills evaluated per skillset
- **Strengths/weaknesses**: Top 5 highest and lowest scored skills

## Color Assignments

Users are assigned colors from the palette in order of selection. Colors cycle if more than 8 users selected.

## Animation

- Polygon vertices animate from center (0) to their values on initial render (300ms ease-out)
- Tab switching cross-fades charts (200ms)
- Gap bars animate width from 0 (200ms staggered)
