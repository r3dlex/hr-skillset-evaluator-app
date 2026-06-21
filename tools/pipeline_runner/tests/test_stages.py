"""Smoke tests for stage command modules."""

from pipeline_runner.stages.archgate import COMMANDS as ARCHGATE_COMMANDS
from pipeline_runner.stages.build import BACKEND_COMMANDS, FRONTEND_COMMANDS
from pipeline_runner.stages.lint import BACKEND_COMMANDS as LINT_BACKEND_COMMANDS
from pipeline_runner.stages.lint import FRONTEND_COMMANDS as LINT_FRONTEND_COMMANDS
from pipeline_runner.stages.test import BACKEND_COMMANDS as TEST_BACKEND_COMMANDS
from pipeline_runner.stages.test import FRONTEND_COMMANDS as TEST_FRONTEND_COMMANDS
from pipeline_runner.stages.typecheck import COMMANDS as TYPECHECK_COMMANDS


def test_stage_command_modules_are_populated() -> None:
    """Static command modules expose the commands used by docs and imports."""
    command_groups = [
        ARCHGATE_COMMANDS,
        BACKEND_COMMANDS,
        FRONTEND_COMMANDS,
        LINT_BACKEND_COMMANDS,
        LINT_FRONTEND_COMMANDS,
        TEST_BACKEND_COMMANDS,
        TEST_FRONTEND_COMMANDS,
        TYPECHECK_COMMANDS,
    ]

    assert all(command_groups)
    assert "npx archgate check" in ARCHGATE_COMMANDS
    assert "npx vue-tsc --noEmit" in TYPECHECK_COMMANDS
