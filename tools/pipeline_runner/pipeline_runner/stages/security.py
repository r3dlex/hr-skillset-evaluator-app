"""Security stage: scan source files for hardcoded secrets."""

import re
from pathlib import Path

# Patterns that indicate hardcoded secrets
SECRET_PATTERNS: list[re.Pattern[str]] = [
    re.compile(r'(?:API_KEY|APIKEY)\s*[:=]\s*["\'][^"\'\s]{8,}["\']', re.IGNORECASE),
    re.compile(r'(?:SECRET_KEY|SECRET)\s*[:=]\s*["\'][^"\'\s]{8,}["\']', re.IGNORECASE),
    re.compile(r'(?:PASSWORD|PASSWD|PWD)\s*[:=]\s*["\'][^"\'\s]{8,}["\']', re.IGNORECASE),
    re.compile(r'(?:TOKEN|AUTH_TOKEN|ACCESS_TOKEN)\s*[:=]\s*["\'][^"\'\s]{8,}["\']', re.IGNORECASE),
    re.compile(r'(?:PRIVATE_KEY)\s*[:=]\s*["\'][^"\'\s]{8,}["\']', re.IGNORECASE),
]

# File extensions to scan
SCAN_EXTENSIONS = {".ex", ".exs", ".ts", ".vue", ".js", ".json"}

# Directories to skip
SKIP_DIRS = {"node_modules", "deps", "_build", ".git", "__pycache__", ".elixir_ls"}

# Files to skip
SKIP_FILES = {".env.example", ".env.sample"}

# File patterns to skip (test files)
SKIP_PATTERNS = ["_test.exs", ".spec.ts", ".test.ts"]


def scan_file(filepath: Path) -> list[tuple[int, str, str]]:
    """Scan a single file for secret patterns.

    Returns list of (line_number, line_content, pattern_matched).
    """
    findings: list[tuple[int, str, str]] = []

    # Skip excluded files
    if filepath.name in SKIP_FILES:
        return findings
    if any(filepath.name.endswith(pat) for pat in SKIP_PATTERNS):
        return findings

    try:
        content = filepath.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return findings

    for line_num, line in enumerate(content.splitlines(), start=1):
        for pattern in SECRET_PATTERNS:
            if pattern.search(line):
                findings.append((line_num, line.strip(), pattern.pattern))
                break  # One finding per line is enough

    return findings


def scan_directory(root: Path) -> dict[str, list[tuple[int, str, str]]]:
    """Scan a directory tree for hardcoded secrets.

    Returns dict mapping file paths to their findings.
    """
    results: dict[str, list[tuple[int, str, str]]] = {}

    for filepath in root.rglob("*"):
        if not filepath.is_file():
            continue
        if filepath.suffix not in SCAN_EXTENSIONS:
            continue
        if any(skip in filepath.parts for skip in SKIP_DIRS):
            continue

        findings = scan_file(filepath)
        if findings:
            results[str(filepath)] = findings

    return results
