"""Tests for the pipeline runner."""

from unittest.mock import MagicMock, patch

import pytest

from pipeline_runner.config import STAGES, StageConfig
from pipeline_runner.runner import StageResult, run_pipeline, run_stage


class TestStageOrdering:
    """Verify stages are defined in the correct order."""

    def test_stage_names(self) -> None:
        expected_order = ["security", "lint", "typecheck", "archgate", "test", "build"]
        actual_order = [s.name for s in STAGES]
        assert actual_order == expected_order

    def test_all_stages_have_commands(self) -> None:
        for stage in STAGES:
            assert len(stage.commands) > 0, f"Stage '{stage.name}' has no commands"

    def test_all_stages_have_names(self) -> None:
        names = [s.name for s in STAGES]
        assert len(names) == len(set(names)), "Duplicate stage names found"


class TestRunStage:
    """Test individual stage execution."""

    @patch("pipeline_runner.runner.subprocess.run")
    def test_successful_stage(self, mock_run: MagicMock) -> None:
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout="OK\n",
            stderr="",
        )

        config = StageConfig(
            name="test-stage",
            commands=["echo hello"],
            workdir="/tmp",
        )

        result = run_stage(config)

        assert result.success is True
        assert result.name == "test-stage"
        assert result.duration_ms >= 0

    @patch("pipeline_runner.runner.subprocess.run")
    def test_failed_stage(self, mock_run: MagicMock) -> None:
        mock_run.return_value = MagicMock(
            returncode=1,
            stdout="",
            stderr="Error: something broke\n",
        )

        config = StageConfig(
            name="failing-stage",
            commands=["false"],
            workdir="/tmp",
        )

        result = run_stage(config)

        assert result.success is False
        assert result.name == "failing-stage"


class TestRunPipeline:
    """Test pipeline orchestration."""

    @patch("pipeline_runner.runner.run_stage")
    def test_fail_fast_stops_on_failure(self, mock_run_stage: MagicMock) -> None:
        """Pipeline should stop at first failure when fail_fast=True."""
        mock_run_stage.side_effect = [
            StageResult(name="security", success=True, output="", duration_ms=100),
            StageResult(name="lint", success=False, output="format error", duration_ms=200),
            # These should not be reached:
            StageResult(name="typecheck", success=True, output="", duration_ms=150),
        ]

        results = run_pipeline(fail_fast=True)

        # Should have stopped after lint failure
        assert len(results) == 2
        assert results[0].success is True
        assert results[1].success is False

    @patch("pipeline_runner.runner.run_stage")
    def test_no_fail_fast_continues(self, mock_run_stage: MagicMock) -> None:
        """Pipeline should continue after failure when fail_fast=False."""
        mock_run_stage.side_effect = [
            StageResult(name="security", success=True, output="", duration_ms=100),
            StageResult(name="lint", success=False, output="format error", duration_ms=200),
            StageResult(name="typecheck", success=True, output="", duration_ms=150),
            StageResult(name="archgate", success=True, output="", duration_ms=120),
            StageResult(name="test", success=True, output="", duration_ms=300),
            StageResult(name="build", success=True, output="", duration_ms=500),
        ]

        results = run_pipeline(fail_fast=False)

        assert len(results) == 6
        assert results[1].success is False  # lint still failed

    @patch("pipeline_runner.runner.run_stage")
    def test_filter_stages(self, mock_run_stage: MagicMock) -> None:
        """Pipeline should only run specified stages."""
        mock_run_stage.return_value = StageResult(
            name="test", success=True, output="", duration_ms=100,
        )

        results = run_pipeline(stages=["test"])

        assert len(results) == 1
        assert results[0].name == "test"

    def test_unknown_stages(self) -> None:
        """Pipeline should return empty list for unknown stages."""
        results = run_pipeline(stages=["nonexistent"])
        assert results == []
