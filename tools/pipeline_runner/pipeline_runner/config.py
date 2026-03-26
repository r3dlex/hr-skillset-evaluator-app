"""Stage definitions with commands and working directories."""

from dataclasses import dataclass, field


@dataclass
class StageConfig:
    """Configuration for a single pipeline stage."""

    name: str
    commands: list[str]
    workdir: str | None = None
    description: str = ""


# Default project root when running inside the pipeline-runner container.
# The project is mounted at /workspace.
PROJECT_ROOT = "/workspace"
BACKEND_DIR = f"{PROJECT_ROOT}/backend"
FRONTEND_DIR = f"{PROJECT_ROOT}/frontend"


STAGES: list[StageConfig] = [
    StageConfig(
        name="security",
        description="Scan for hardcoded secrets in source files",
        commands=[
            (
                "grep -rn"
                " --include='*.ex' --include='*.exs' --include='*.ts' --include='*.vue'"
                " --include='*.js' --include='*.json'"
                " --exclude-dir=node_modules --exclude-dir=deps --exclude-dir=_build"
                " --exclude='.env.example' --exclude='*_test.exs' --exclude='*.spec.ts'"
                " -iE '(API_KEY|SECRET_KEY|PASSWORD|TOKEN|PRIVATE_KEY)\\s*[:=]\\s*[\"'\\'][^\"'\\' ]{8,}'"
                f" {PROJECT_ROOT}/backend {PROJECT_ROOT}/frontend/src"
                " && echo 'SECRETS_FOUND' || true"
            ),
        ],
        workdir=PROJECT_ROOT,
    ),
    StageConfig(
        name="lint",
        description="Check code formatting and linting",
        commands=[
            "mix format --check-formatted",
            "npx eslint src --ext .ts,.vue",
        ],
        workdir=None,  # set per-command in stages
    ),
    StageConfig(
        name="typecheck",
        description="Run TypeScript type checking",
        commands=[
            "npx vue-tsc --noEmit",
        ],
        workdir=FRONTEND_DIR,
    ),
    StageConfig(
        name="archgate",
        description="Check architecture decision compliance",
        commands=[
            "npx archgate check",
        ],
        workdir=PROJECT_ROOT,
    ),
    StageConfig(
        name="test",
        description="Run backend and frontend tests",
        commands=[
            "mix test",
            "npm test",
        ],
        workdir=None,  # set per-command in stages
    ),
    StageConfig(
        name="build",
        description="Build frontend assets and Elixir release",
        commands=[
            "npm run build",
            "MIX_ENV=prod mix release --overwrite",
        ],
        workdir=None,  # set per-command in stages
    ),
]


# Override workdirs for stages with mixed backend/frontend commands
_LINT_COMMANDS_WITH_DIRS = [
    (f"cd {BACKEND_DIR} && mix format --check-formatted", BACKEND_DIR),
    (f"cd {FRONTEND_DIR} && npx eslint src --ext .ts,.vue", FRONTEND_DIR),
]

_TEST_COMMANDS_WITH_DIRS = [
    (f"cd {BACKEND_DIR} && mix test", BACKEND_DIR),
    (f"cd {FRONTEND_DIR} && npm test", FRONTEND_DIR),
]

_BUILD_COMMANDS_WITH_DIRS = [
    (f"cd {FRONTEND_DIR} && npm run build", FRONTEND_DIR),
    (f"cd {BACKEND_DIR} && MIX_ENV=prod mix release --overwrite", BACKEND_DIR),
]

# Patch the stages that need per-command working directories
for stage in STAGES:
    if stage.name == "lint":
        stage.commands = [cmd for cmd, _ in _LINT_COMMANDS_WITH_DIRS]
        stage.workdir = PROJECT_ROOT
    elif stage.name == "test":
        stage.commands = [cmd for cmd, _ in _TEST_COMMANDS_WITH_DIRS]
        stage.workdir = PROJECT_ROOT
    elif stage.name == "build":
        stage.commands = [cmd for cmd, _ in _BUILD_COMMANDS_WITH_DIRS]
        stage.workdir = PROJECT_ROOT
