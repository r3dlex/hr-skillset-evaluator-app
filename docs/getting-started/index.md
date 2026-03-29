# Quick Start

Get the SkillForge running locally in under five minutes using Docker.

## Prerequisites

- **Docker** and **Docker Compose** installed on your machine
- A modern web browser (Chrome, Firefox, Safari, Edge)

## Starting the Application

Clone the repository and start the application with Docker Compose:

```bash
git clone https://github.com/your-org/hr-skillset-evaluator-app.git
cd hr-skillset-evaluator-app
docker compose up --build
```

The application will be available at **http://localhost:4000**.

::: tip
On first startup, the database is created automatically. No manual migration step is needed.
:::

## First Login

When you open the app for the first time you will be presented with a login screen. Use the credentials provided by your administrator, or -- if you are running a fresh local instance -- check the seed data configuration for default users.

## Initial Setup for Managers

After logging in as a manager, follow these steps to get productive:

1. **Import a skill matrix** -- Navigate to the import page and upload an `.xlsx` file containing your team's skillsets and skill groups.
2. **Create an assessment** -- Go to the Assessments section and create your first assessment period.
3. **Start evaluating** -- Select team members and begin entering skill scores.

::: info
See the [Manager Workflow](/guides/manager-workflow) guide for a detailed walkthrough of the full process.
:::

## Running Tests

Backend tests can be run inside Docker:

```bash
docker compose run --rm app mix test
```

Frontend tests:

```bash
cd frontend
npm run test
```

## Environment Variables

All configuration is handled through environment variables. No secrets should ever be committed to the repository. Common variables include:

| Variable | Description |
|---|---|
| `SECRET_KEY_BASE` | Phoenix secret key for sessions |
| `DATABASE_PATH` | Path to the SQLite database file |
| `PHX_HOST` | Hostname for the Phoenix server |
| `OPENAI_API_KEY` | API key for the AI assistant feature |

## Next Steps

- Take the [App Tour](/getting-started/tour) to familiarize yourself with the interface
- Review [Roles & Permissions](/reference/roles) to understand access levels
- Check the [Onboarding](/guides/onboarding) guide for the built-in checklist
