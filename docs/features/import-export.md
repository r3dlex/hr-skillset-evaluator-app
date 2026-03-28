# Import & Export

## Importing Skill Matrices (XLSX)

Managers can import team skill data from Excel spreadsheets.

### How to Import

1. Go to **Settings** → **Skillsets**
2. Click **Import xlsx**
3. Select your Excel file
4. Choose the assessment (period) for the imported data
5. Review and confirm

### File Format

The xlsx file should contain:
- Column headers matching skill names
- Rows for each team member (matched by email or name)
- Score values from 0 to 5

::: warning
Importing will upsert data — existing scores for the same user/skill/period combination will be updated, not duplicated.
:::

## Exporting Evaluations

To export evaluation data:

1. Navigate to any skillset
2. Use the **Export** option in Settings
3. Select the assessment and format
4. Download the generated xlsx file

The export includes manager scores, self-scores, and metadata for all team members in the selected context.
