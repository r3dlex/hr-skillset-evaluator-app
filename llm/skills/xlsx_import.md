# Skill: XLSX Import

## Overview

The SkillMatrix.xlsx file is the primary data source for skill evaluations.
It contains team structures, user data, and evaluation scores across multiple skill sheets.

## File Format

The xlsx file has the following structure:

### Teams Sheet
- Columns: Team Name, Members (comma-separated email list)
- Used to set up team structure and assign users to teams

### Skill Sheets (one per skillset: Domain, Fullstack, UX, Product, AI, Softskills)

| Row | Content |
|-----|---------|
| 1   | Skill group names (merged cells spanning group columns) |
| 2   | Priority per skill: Critical, High, Medium, Low (may include emoji: "Red Circle Critical") |
| 3   | Headers: Team, Location, Role, Name, then one column per skill |
| 4+  | Data rows: team name, location, role, person name, then scores (0-5) |

## Import Pipeline

1. **Parse teams sheet** -> create/update teams and user-team memberships
2. **Parse skill structure** (rows 1-3) -> create/update skillsets, skill_groups, skills
3. **Parse data rows** (row 4+) -> create PersonRow structs with user info + scores
4. **Process rows** concurrently -> upsert evaluations with manager scores

### Key Behaviors

- **Idempotent**: Re-importing the same file updates existing records (upsert).
- **Job title normalization**: "Dev.", "Developer" -> "Dev"; "DevOps Eng." -> "DevOps"
- **Role normalization**: "Lead", "Head", "Director" -> "manager" role
- **Priority parsing**: Strips emoji prefixes ("Red Circle Critical" -> "critical")
- **Skillset-role mapping**: Determines which roles see which skillsets (e.g., Fullstack visible to Dev, QE, DevOps, Lead)

## How to Trigger Import

### Via Chat (Tool Use)
When a Manager/Admin asks to import data:

1. User uploads the xlsx file via the chat interface
2. The file is saved to a temp path: `/tmp/chat_upload_{ref}.xlsx`
3. Suggest a **dry run first**:
   ```
   I'll validate the file first without making changes.
   ```
   Tool call: `import_xlsx(file_ref: "abc123", period: "2026-H1", dry_run: true)`

4. If dry run succeeds, confirm with user and run the actual import:
   ```
   The file looks good — found 182 people across 23 teams. Shall I proceed with the import?
   ```
   Tool call: `import_xlsx(file_ref: "abc123", period: "2026-H1")`

### Via API
```
POST /api/import/xlsx
Content-Type: multipart/form-data
Body: file=@SkillMatrix.xlsx, period=2026-H1
```

## Expected Output

```
Import completed. 182 rows processed, 1820 evaluations created, 0 updated. 0 errors.
```

## Common Issues

- **Missing team sheet**: File must have a "Teams" sheet for user-team mapping
- **Blank rows**: Empty rows in skill sheets are skipped
- **Unknown roles**: Roles not in the known list are assigned "user" role
- **Duplicate names**: Users are matched by email; if email is missing, by name + team
- **Score format**: Non-numeric scores are treated as null (no evaluation)
