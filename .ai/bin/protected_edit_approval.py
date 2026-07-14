#!/usr/bin/env python3
"""Prepare and verify exact manifest-bound protected-edit block approvals."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import re
import stat
import subprocess
import sys
from collections.abc import Iterable, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import TextIO

INDIVIDUAL_PREFIX = "confirm-protected-edit "
BLOCK_PREFIX = "confirm-protected-edit-block "
CATEGORY_PATTERN = re.compile(r"^[a-z0-9][a-z0-9-]*$")
TICKET_PATTERN = re.compile(r"^[A-Z][A-Z0-9]*-[0-9]+$")
SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")
AUDIT_LOG_NAME = "protected-edit-approvals.jsonl"


class ApprovalError(ValueError):
    """Raised when an approval or manifest is invalid."""


@dataclass(frozen=True)
class Manifest:
    lines: tuple[str, ...]
    content: bytes
    sha256: str

    @property
    def count(self) -> int:
        return len(self.lines)


def parse_individual_command(line: str) -> tuple[str, str]:
    if not line.startswith(INDIVIDUAL_PREFIX):
        raise ApprovalError(f"invalid individual approval command: {line!r}")
    remainder = line[len(INDIVIDUAL_PREFIX) :]
    category, separator, path = remainder.partition(" ")
    if not separator or not CATEGORY_PATTERN.fullmatch(category):
        raise ApprovalError(f"invalid protected-edit category: {category!r}")
    components = path.split("/")
    if (
        not path
        or path != path.strip()
        or path.startswith("/")
        or path.endswith("/")
        or "\\" in path
        or "\x00" in path
        or "\r" in path
        or "\n" in path
        or any(
            component in {"", ".", ".."} or component != component.strip()
            for component in components
        )
        or re.match(r"^[A-Za-z]:", path)
    ):
        raise ApprovalError(f"invalid repository-relative path: {path!r}")
    return category, path


def canonical_manifest(lines: Iterable[str]) -> Manifest:
    commands: set[str] = set()
    for raw_line in lines:
        line = raw_line.rstrip("\r\n")
        if not line:
            continue
        parse_individual_command(line)
        commands.add(line)
    if not commands:
        raise ApprovalError("manifest is empty")
    canonical_lines = tuple(sorted(commands, key=lambda value: value.encode("utf-8")))
    content = ("\n".join(canonical_lines) + "\n").encode("utf-8")
    return Manifest(
        lines=canonical_lines,
        content=content,
        sha256=hashlib.sha256(content).hexdigest(),
    )


def contains_agent_config(manifest: Manifest) -> bool:
    for line in manifest.lines:
        category, path = parse_individual_command(line)
        components = tuple(component.casefold() for component in path.split("/"))
        if (
            category == "agent-config"
            or ".agents" in components
            or components[-1] == "agents.md"
        ):
            return True
    return False


def validate_ticket(ticket: str) -> None:
    if not TICKET_PATTERN.fullmatch(ticket):
        raise ApprovalError(f"invalid ticket: {ticket!r}")


def validate_head(head_sha: str) -> None:
    if not re.fullmatch(r"(?:[0-9a-fA-F]{40}|[0-9a-fA-F]{64})", head_sha):
        raise ApprovalError(f"invalid Git HEAD SHA: {head_sha!r}")


def block_phrase(ticket: str, head_sha: str, manifest: Manifest) -> str:
    validate_ticket(ticket)
    validate_head(head_sha)
    if contains_agent_config(manifest):
        raise ApprovalError("block approval is forbidden for agent-config")
    return f"{BLOCK_PREFIX}{ticket} {head_sha} {manifest.count} {manifest.sha256}"


def verify_block_phrase(
    phrase: str,
    *,
    ticket: str,
    head_sha: str,
    manifest: Manifest,
) -> None:
    expected = block_phrase(ticket, head_sha, manifest)
    if phrase != expected:
        raise ApprovalError(f"block approval mismatch; expected: {expected}")


def git_directory(repository: Path) -> Path:
    """Return the repository's trusted, worktree-specific Git metadata directory."""
    metadata = repository.resolve() / ".git"
    if metadata.is_symlink():
        raise ApprovalError(f"Git metadata must not be a symlink: {metadata}")
    if metadata.is_file():
        declaration = metadata.read_text(encoding="utf-8").strip()
        prefix = "gitdir: "
        if not declaration.startswith(prefix):
            raise ApprovalError(f"invalid Git metadata pointer: {metadata}")
        git_dir = Path(declaration[len(prefix) :])
        if not git_dir.is_absolute():
            git_dir = metadata.parent / git_dir
        git_dir = git_dir.resolve()
    elif metadata.is_dir():
        git_dir = metadata.resolve()
    else:
        raise ApprovalError(f"Git metadata not found: {metadata}")
    if not git_dir.is_dir():
        raise ApprovalError(f"Git metadata directory not found: {git_dir}")
    return git_dir


def audit_log_path(repository: Path) -> Path:
    """Return the fixed audit destination inside worktree-specific Git metadata."""
    return git_directory(repository) / AUDIT_LOG_NAME


def append_audit_records(
    repository: Path,
    *,
    phrase: str,
    ticket: str,
    head_sha: str,
    manifest: Manifest,
    timestamp: str | None = None,
) -> None:
    """Append one durable JSONL record for every approved manifest entry."""
    audit_log = audit_log_path(repository)
    if audit_log.is_symlink():
        raise ApprovalError(f"approval audit must not be a symlink: {audit_log}")
    recorded_at = timestamp or dt.datetime.now(dt.UTC).isoformat().replace(
        "+00:00", "Z"
    )
    phrase_sha256 = hashlib.sha256(phrase.encode("utf-8")).hexdigest()
    records = []
    for line in manifest.lines:
        category, path = parse_individual_command(line)
        records.append(
            {
                "approval_mode": "block",
                "approver_phrase_sha256": phrase_sha256,
                "category": category,
                "head_sha": head_sha,
                "manifest_count": manifest.count,
                "manifest_sha256": manifest.sha256,
                "path": path,
                "recorded_at": recorded_at,
                "ticket": ticket,
            }
        )
    payload = "".join(
        json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n"
        for record in records
    ).encode("utf-8")
    no_follow = getattr(os, "O_NOFOLLOW", None)
    non_block = getattr(os, "O_NONBLOCK", None)
    if no_follow is None or non_block is None:
        raise ApprovalError("safe nonblocking no-follow audit writes are unavailable")
    try:
        descriptor = os.open(
            audit_log,
            os.O_APPEND | os.O_CREAT | os.O_WRONLY | no_follow | non_block,
            0o600,
        )
    except OSError as exc:
        raise ApprovalError(f"unable to open approval audit: {audit_log}") from exc
    try:
        metadata = os.fstat(descriptor)
        if not stat.S_ISREG(metadata.st_mode) or metadata.st_nlink != 1:
            raise ApprovalError(
                f"approval audit must be one regular, unlinked path: {audit_log}"
            )
        view = memoryview(payload)
        while view:
            written = os.write(descriptor, view)
            if written <= 0:
                raise ApprovalError(f"unable to append approval audit: {audit_log}")
            view = view[written:]
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


def verify_current_and_audit(
    *,
    repository: Path,
    phrase: str,
    ticket: str,
    manifest: Manifest,
) -> str:
    """Verify against the current HEAD, recheck it, then append audit records."""
    validate_manifest_paths(repository, manifest)
    head_sha = current_head(repository)
    verify_block_phrase(
        phrase,
        ticket=ticket,
        head_sha=head_sha,
        manifest=manifest,
    )
    if current_head(repository) != head_sha:
        raise ApprovalError("Git HEAD changed during protected-edit verification")
    append_audit_records(
        repository,
        phrase=phrase,
        ticket=ticket,
        head_sha=head_sha,
        manifest=manifest,
    )
    return head_sha


def current_head(repository: Path) -> str:
    git_dir = git_directory(repository)
    head = (git_dir / "HEAD").read_text(encoding="utf-8").strip()
    if not head.startswith("ref: "):
        validate_head(head)
        return head

    reference = head[len("ref: ") :]
    common_dir = git_dir
    common_dir_pointer = git_dir / "commondir"
    if common_dir_pointer.is_file():
        common_dir = (
            git_dir / common_dir_pointer.read_text(encoding="utf-8").strip()
        ).resolve()
    for candidate in (git_dir / reference, common_dir / reference):
        if candidate.is_file():
            resolved = candidate.read_text(encoding="utf-8").strip()
            validate_head(resolved)
            return resolved
    packed_refs = common_dir / "packed-refs"
    if packed_refs.is_file():
        suffix = f" {reference}"
        for line in packed_refs.read_text(encoding="utf-8").splitlines():
            if line.endswith(suffix):
                resolved = line.split(" ", 1)[0]
                validate_head(resolved)
                return resolved
    raise ApprovalError(f"unable to resolve Git HEAD reference: {reference}")


def read_manifest(source: TextIO) -> Manifest:
    return canonical_manifest(source)


def validate_manifest_paths(repository: Path, manifest: Manifest) -> None:
    root = repository.resolve()
    metadata_marker = root / ".git"
    metadata_marker_resolved = metadata_marker.resolve()
    git_dir = git_directory(repository)
    for line in manifest.lines:
        _, path = parse_individual_command(line)
        if path.split("/", 1)[0].casefold() == ".git":
            raise ApprovalError(f"protected-edit path targets Git metadata: {path!r}")
        candidate = root
        for component in path.split("/"):
            candidate /= component
            if candidate.is_symlink():
                raise ApprovalError(f"protected-edit path contains a symlink: {path!r}")
            if not candidate.exists():
                break
        target = (root / path).resolve()
        if target == metadata_marker_resolved or (
            target.exists() and target.samefile(metadata_marker)
        ):
            raise ApprovalError(f"protected-edit path aliases Git metadata: {path!r}")
        if target.is_file() and target.stat().st_nlink != 1:
            raise ApprovalError(
                f"protected-edit path has multiple hard links: {path!r}"
            )
        try:
            target.relative_to(root)
        except ValueError as exc:
            raise ApprovalError(
                f"protected-edit path escapes repository: {path!r}"
            ) from exc
        try:
            target.relative_to(git_dir)
        except ValueError:
            continue
        raise ApprovalError(f"protected-edit path targets Git metadata: {path!r}")


def check_repository(repository: Path) -> None:
    policy_path = repository / ".ai/rules/protected-edit-approvals.md"
    agents_path = repository / "AGENTS.md"
    if not policy_path.is_file():
        raise ApprovalError(f"missing policy: {policy_path}")
    if not agents_path.is_file():
        raise ApprovalError(f"missing agent guidance: {agents_path}")
    policy = policy_path.read_text(encoding="utf-8")
    agents = agents_path.read_text(encoding="utf-8")
    required_policy_text = (
        "confirm-protected-edit <category> <relative-path>",
        "confirm-protected-edit-block <TICKET> <HEAD_SHA> <COUNT> <MANIFEST_SHA256>",
        "sorted by the UTF-8 bytes",
        "one final LF",
        "lowercase SHA-256",
        "agent-config",
        "one append-only audit record per manifest",
        "one-by-one flow",
        "recommendation",
    )
    for expected in required_policy_text:
        if expected not in policy:
            raise ApprovalError(f"policy is missing required text: {expected}")
    if ".ai/rules/protected-edit-approvals.md" not in agents:
        raise ApprovalError(
            "AGENTS.md does not link the protected-edit approval policy"
        )


def run_regression_tests(repository: Path) -> None:
    test_file = repository / ".ai/tests/test_protected_edit_approval.py"
    completed = subprocess.run(
        [sys.executable, str(test_file)],
        cwd=repository,
        check=False,
    )
    if completed.returncode != 0:
        raise ApprovalError(
            f"protected-edit regression tests failed with exit code {completed.returncode}"
        )


def self_test() -> None:
    head_sha = "a" * 40
    manifest = canonical_manifest(
        [
            "confirm-protected-edit package-versions z.csproj",
            "confirm-protected-edit auth a.cs",
            "confirm-protected-edit auth a.cs",
        ]
    )
    if manifest.count != 2 or manifest.content[-1:] != b"\n":
        raise ApprovalError("canonical manifest self-test failed")
    phrase = block_phrase("DEV-1", head_sha, manifest)
    verify_block_phrase(
        phrase,
        ticket="DEV-1",
        head_sha=head_sha,
        manifest=manifest,
    )
    agent_config = canonical_manifest(
        ["confirm-protected-edit agent-config .agents/agents/coder.md"]
    )
    try:
        block_phrase("DEV-1", head_sha, agent_config)
    except ApprovalError:
        return
    raise ApprovalError("agent-config block rejection self-test failed")


def open_input(path: str) -> TextIO:
    if path == "-":
        return sys.stdin
    return Path(path).open("r", encoding="utf-8", newline="")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    prepare = subparsers.add_parser(
        "prepare", help="print a canonical manifest and block phrase"
    )
    prepare.add_argument("--ticket", required=True)
    prepare.add_argument("--repository", type=Path, default=Path.cwd())
    prepare.add_argument("--input", default="-")

    verify = subparsers.add_parser("verify", help="verify an exact block phrase")
    verify.add_argument("--ticket", required=True)
    verify.add_argument("--repository", type=Path, default=Path.cwd())
    verify.add_argument("--input", default="-")
    verify.add_argument("--phrase", required=True)

    check = subparsers.add_parser(
        "check-repository", help="validate repository policy wiring"
    )
    check.add_argument("--repository", type=Path, default=Path.cwd())
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.command == "check-repository":
            check_repository(args.repository.resolve())
            print("Protected-edit approval policy validation passed")
            return 0

        with open_input(args.input) as source:
            manifest = read_manifest(source)
        if args.command == "prepare":
            validate_manifest_paths(args.repository, manifest)
            head_sha = current_head(args.repository)
            phrase = block_phrase(args.ticket, head_sha, manifest)
            sys.stdout.buffer.write(manifest.content)
            print(f"COUNT: {manifest.count}")
            print(f"MANIFEST_SHA256: {manifest.sha256}")
            print(f"BLOCK_PHRASE: {phrase}")
            return 0
        verify_current_and_audit(
            repository=args.repository,
            phrase=args.phrase,
            ticket=args.ticket,
            manifest=manifest,
        )
        print("Protected-edit block approval verified")
        return 0
    except (ApprovalError, OSError, UnicodeError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
