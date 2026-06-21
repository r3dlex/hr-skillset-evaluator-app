"""CLI tests for the pipeline runner."""

from click.testing import CliRunner
from pipeline_runner.__main__ import main
from pipeline_runner.runner import StageResult


def test_cli_success(monkeypatch) -> None:  # type: ignore[no-untyped-def]
    """CLI exits cleanly when all selected stages pass."""

    def fake_run_pipeline(
        stages: list[str] | None = None, fail_fast: bool = True
    ) -> list[StageResult]:
        assert stages == ["test"]
        assert fail_fast is False
        return [StageResult(name="test", success=True, output="", duration_ms=12)]

    monkeypatch.setattr("pipeline_runner.__main__.run_pipeline", fake_run_pipeline)

    result = CliRunner().invoke(main, ["--stages", "test", "--no-fail-fast"])

    assert result.exit_code == 0
    assert "1 passed, 0 failed" in result.output


def test_cli_failure_exits_nonzero(monkeypatch) -> None:  # type: ignore[no-untyped-def]
    """CLI exits with code 1 when a stage fails."""

    def fake_run_pipeline(
        stages: list[str] | None = None, fail_fast: bool = True
    ) -> list[StageResult]:
        assert stages is None
        assert fail_fast is True
        return [StageResult(name="lint", success=False, output="bad", duration_ms=7)]

    monkeypatch.setattr("pipeline_runner.__main__.run_pipeline", fake_run_pipeline)

    result = CliRunner().invoke(main, [])

    assert result.exit_code == 1
    assert "0 passed, 1 failed" in result.output
