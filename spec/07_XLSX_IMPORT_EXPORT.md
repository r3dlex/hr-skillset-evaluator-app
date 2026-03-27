# 07 — XLSX Import/Export

## Import Flow

### Parsing Strategy

Uses `xlsxir` (Elixir library) to parse xlsx in-memory. Processing is handled via a **Broadway pipeline** (`SkillsetEvaluator.Import.Pipeline`) for concurrent batch upserts.

### Architecture (Broadway)

```
xlsx file
  │
  ├── XlsxParser.parse_teams_sheet/1  →  Upsert teams + users (sequential)
  │
  └── XlsxParser.parse/2  →  [PersonRow, PersonRow, ...]
                                    │
                            Task.async_stream (concurrent)
                                    │
                            ┌───────┴────────┐
                            │ Per PersonRow:  │
                            │ 1. ensure_team  │
                            │ 2. find_user    │
                            │ 3. ensure_skill │
                            │ 4. upsert_eval  │
                            └────────────────┘
```

The pipeline module (`Import.Pipeline`) also implements Broadway callbacks for future async mode. Currently uses `Task.async_stream` for simpler synchronous-but-concurrent processing within a single request.

### Sheet Structure (from SkillMatrix.xlsx)

Each skill sheet (Softskills, Domain, Fullstack, Product, AI, UX) follows this layout:

```
Row 1: [empty, empty, empty, empty, GROUP_A, ..., GROUP_B, ...]  ← Skill group headers (merged cells)
Row 2: [empty, empty, empty, empty, priority, priority, ...]      ← Priority per skill (Critical/High/Medium)
Row 3: [Team,  Location, Role, Name/Skill, Skill1, Skill2, ...]   ← Column headers + skill names
Row 4+: [BIM,  DE,    Lead,  Florian Haag,  4,      3,     ...]   ← Person data + scores
```

### Teams Sheet

```
Row 1: [Team, Name, Email, User, Role, Location, Active]
Row 2+: [BIM, Florian Haag, florian@..., fhaag, Lead, DE, Yes]
```

### Import Algorithm

1. **Parse Teams sheet first**: Upsert teams and users
2. **For each skill sheet**:
   a. Map sheet name → skillset (create if not exists)
   b. Parse row 1 → skill groups (detect merged cell ranges for group spans)
   c. Parse row 2 → priorities per skill column
   d. Parse row 3 → skill names per column
   e. Create skill_groups and skills records
   f. For rows 4+:
      - Match person by name + team → user_id
      - For each score cell: upsert evaluation with manager_score

### Conflict Resolution

- **Users**: Matched by (name, team). If not found, create new user with role "user".
- **Skills**: Matched by (name, skill_group). If not found, create new.
- **Evaluations**: Upserted on (user_id, skill_id, period). Import overwrites manager_score.

### Validation

- Scores must be integers 0-5 (or nil/empty for unrated)
- Sheet names must be non-empty
- Person rows must have a name in column D
- Skip completely empty rows

## Export Flow

### Algorithm

1. Query all skillsets with groups, skills
2. For each skillset, create a worksheet:
   a. Row 1: skill group names at their starting column positions
   b. Row 2: skill priorities
   c. Row 3: "Team", "Location", "Role", "Name/Skill", skill names...
   d. Row 4+: user data + manager_scores
3. Create Teams worksheet with master roster
4. Generate xlsx binary using `elixir_make_xlsx` or `xlsxir` write mode

### Format Preservation

Export matches the original xlsx format so re-import is idempotent.

## UI Integration

### Import (Manager)

- Drag-and-drop zone or file picker
- Period selector (e.g., "2025-Q1")
- Preview: show parsed row count + new skills detected before confirming
- Progress bar during import
- Result summary: users imported, evaluations created, errors

### Export (Manager)

- Select skillset(s) and period
- Download button triggers `/api/export/xlsx`
- Browser downloads the file

## Edge Cases

- Merged cells in row 1 span multiple skill columns → detect via cell range
- Empty score cells → null (not 0)
- Duplicate names in same team → log warning, skip
- Unicode characters in names → preserve as-is
- Very large sheets (100+ columns) → stream processing via xlsxir

## Chat-Triggered Import (Phase 9)

### Chat-Triggered Import

The AI chat agent can trigger xlsx imports for Manager and Admin users.
The agent has an internal `import_xlsx` tool that calls the existing
`Import.Pipeline.run_import/3`. The flow:

1. Manager uploads xlsx via chat upload endpoint
2. Agent validates: role check, file exists, period format
3. Agent calls Broadway pipeline
4. Agent streams progress: "Processing... 45 users found... Import complete."

Endpoint: `POST /api/chat/conversations/:id/upload` (Manager/Admin only)
