# 13 — Design System

## Color Palette

### Primary Colors

| Name | Hex | Usage |
|------|-----|-------|
| Primary Blue | `#3b82f6` | Buttons, links, active states |
| Primary Dark | `#1e40af` | Hover states, emphasis |
| Primary Light | `#dbeafe` | Backgrounds, badges |

### Neutral Colors

| Name | Hex | Usage |
|------|-----|-------|
| Sidebar Dark | `#1a1a2e` | Sidebar background |
| Sidebar Text | `#94a3b8` | Sidebar inactive text |
| Sidebar Active | `#ffffff` | Sidebar active item |
| Background | `#f8f9fa` | Main content area |
| Surface | `#ffffff` | Cards, panels |
| Border | `#e2e8f0` | Card borders, dividers |
| Text Primary | `#1e293b` | Headings, body text |
| Text Secondary | `#64748b` | Labels, descriptions |
| Text Muted | `#94a3b8` | Placeholders, hints |

### Status Colors

| Name | Hex | Usage |
|------|-----|-------|
| Success | `#22c55e` | Aligned gaps, positive |
| Warning | `#f59e0b` | Small gaps (1 point) |
| Danger | `#ef4444` | Large gaps (2+ points) |

### Radar Chart Palette (8 colors, cycling)

```
#3b82f6  — Blue
#ef4444  — Red
#22c55e  — Green
#f59e0b  — Amber
#8b5cf6  — Violet
#06b6d4  — Cyan
#f97316  — Orange
#ec4899  — Pink
```

### Priority Colors

| Priority | Color | Badge Style |
|----------|-------|-------------|
| Critical | `#ef4444` bg, `#ffffff` text | Red badge |
| High | `#f59e0b` bg, `#ffffff` text | Amber badge |
| Medium | `#3b82f6` bg, `#ffffff` text | Blue badge |

## Typography

### Font Family

```css
font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
```

Load via Google Fonts or bundle in assets.

### Scale

| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| heading-xl | 24px | 700 | Page titles |
| heading-lg | 20px | 600 | Section headers |
| heading-md | 16px | 600 | Card titles |
| body | 14px | 400 | Body text |
| body-sm | 13px | 400 | Table cells, secondary |
| caption | 12px | 400 | Labels, badges |
| caption-xs | 11px | 500 | Radar chart axis labels |

## Spacing

Base unit: 4px

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Tight gaps |
| sm | 8px | Element spacing |
| md | 16px | Card padding |
| lg | 24px | Section spacing |
| xl | 32px | Page margins |
| 2xl | 48px | Major sections |

## Component Styles

### Cards

```css
background: #ffffff;
border: 1px solid #e2e8f0;
border-radius: 12px;
padding: 24px;
box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
```

### Sidebar

```css
background: #1a1a2e;
width: 260px;
padding: 24px 16px;
```

### Buttons

```css
/* Primary */
background: #3b82f6;
color: #ffffff;
border-radius: 8px;
padding: 8px 16px;
font-size: 14px;
font-weight: 500;

/* Secondary */
background: transparent;
border: 1px solid #e2e8f0;
color: #1e293b;
```

### Input Fields

```css
border: 1px solid #e2e8f0;
border-radius: 8px;
padding: 8px 12px;
font-size: 14px;
```

### Score Slider

- Track: 200px wide, 4px height, `#e2e8f0`
- Thumb: 16px circle, `#3b82f6`
- Fill: `#3b82f6` from left to thumb
- Labels: 0-5 below track

### Tabs

```css
/* Inactive */
color: #64748b;
border-bottom: 2px solid transparent;
padding: 8px 16px;

/* Active */
color: #3b82f6;
border-bottom: 2px solid #3b82f6;
font-weight: 600;
```

## Tailwind Configuration

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        sidebar: { DEFAULT: '#1a1a2e' },
        primary: { DEFAULT: '#3b82f6', dark: '#1e40af', light: '#dbeafe' },
      },
      fontFamily: {
        sans: ['Inter', ...defaultTheme.fontFamily.sans],
      },
    },
  },
}
```

## RIB Theme

| Token | Light | Dark |
|-------|-------|------|
| Primary | `#0078B8` | `#4DA6D9` |
| Sidebar | `#003B5C` | `#001F33` |
| Background | `#F5F7FA` | `#0A1628` |
| Surface | `#FFFFFF` | `#132238` |
| Text Primary | `#1A2B3C` | `#E8EDF2` |
| Accent | `#00A3E0` | `#00A3E0` |

The RIB theme uses the company's blue-teal palette. Logo switches to RibLogo.vue.

## Collapsible Sidebar

| State | Width | Content |
|-------|-------|---------|
| Expanded | 260px | Logo, nav labels, skillset list, user info |
| Collapsed | 64px | Icons only, tooltips on hover, mini logo |

Toggle via chevron button at sidebar bottom.

## Layout Structure

```
┌──────────┬───────────────────────────────────────┐
│          │  Header (breadcrumbs, user menu)       │
│ Sidebar  ├───────────────────────────────────────┤
│ (260px)  │                                       │
│          │  Content Area                          │
│ - Logo   │  ┌─────────────┐ ┌─────────────┐     │
│ - Nav    │  │ Radar Chart │ │ Team Legend  │     │
│ - Teams  │  │             │ │             │     │
│ - Skills │  └─────────────┘ └─────────────┘     │
│          │  ┌───────────────────────────────┐     │
│          │  │ Data Table / Gap Analysis      │     │
│          │  └───────────────────────────────┘     │
└──────────┴───────────────────────────────────────┘
```
