"""Tests for the security scanning stage."""

from pathlib import Path

from pipeline_runner.stages.security import scan_directory, scan_file


def test_scan_file_detects_secret(tmp_path: Path) -> None:
    """Secret-looking assignments are reported with their line number."""
    source = tmp_path / "config.ts"
    source.write_text('const API_KEY = "abcd1234secret";\n', encoding="utf-8")

    findings = scan_file(source)

    assert len(findings) == 1
    assert findings[0][0] == 1
    assert "API_KEY" in findings[0][1]


def test_scan_file_skips_example_and_test_files(tmp_path: Path) -> None:
    """Example env and test files are skipped."""
    env_file = tmp_path / ".env.example"
    env_file.write_text('SECRET_KEY="abcd1234secret"\n', encoding="utf-8")
    test_file = tmp_path / "user_test.exs"
    test_file.write_text('TOKEN="abcd1234secret"\n', encoding="utf-8")

    assert scan_file(env_file) == []
    assert scan_file(test_file) == []


def test_scan_directory_skips_excluded_dirs(tmp_path: Path) -> None:
    """Directory scan skips dependency folders and reports source findings."""
    src = tmp_path / "src"
    src.mkdir()
    source = src / "app.ts"
    source.write_text('const TOKEN = "abcd1234secret";\n', encoding="utf-8")
    node_modules = tmp_path / "node_modules"
    node_modules.mkdir()
    ignored = node_modules / "app.ts"
    ignored.write_text('const TOKEN = "abcd1234secret";\n', encoding="utf-8")

    results = scan_directory(tmp_path)

    assert str(source) in results
    assert str(ignored) not in results


def test_scan_file_handles_missing_file(tmp_path: Path) -> None:
    """Unreadable or missing files produce no findings."""
    assert scan_file(tmp_path / "missing.ts") == []
