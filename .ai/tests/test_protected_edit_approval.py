#!/usr/bin/env python3
from __future__ import annotations

import contextlib
import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / ".ai/bin"))
import protected_edit_approval as policy  # noqa: E402


class CanonicalManifestTests(unittest.TestCase):
    def test_sorts_by_utf8_bytes_removes_duplicates_and_adds_final_lf(self) -> None:
        manifest = policy.canonical_manifest(
            [
                "confirm-protected-edit package-versions z.csproj\n",
                "confirm-protected-edit auth a.cs\r\n",
                "confirm-protected-edit auth a.cs\n",
            ]
        )
        self.assertEqual(
            manifest.lines,
            (
                "confirm-protected-edit auth a.cs",
                "confirm-protected-edit package-versions z.csproj",
            ),
        )
        self.assertEqual(manifest.content[-1:], b"\n")
        self.assertEqual(len(manifest.sha256), 64)

    def test_rejects_noncanonical_or_escaping_paths(self) -> None:
        invalid_paths = (
            "/absolute.cs",
            "../outside.cs",
            "backend/../outside.cs",
            "./backend/a.cs",
            "backend\\a.cs",
            "C:\\Windows\\system32\\drivers\\etc\\hosts",
            " leading-space.cs",
            "trailing-space.cs ",
            "backend/ leading-space.cs",
            "backend/trailing-space.cs ",
            "backend/ /a.cs",
            "backend//a.cs",
            "backend/",
        )
        for path in invalid_paths:
            with self.subTest(path=path), self.assertRaises(policy.ApprovalError):
                policy.canonical_manifest([f"confirm-protected-edit auth {path}"])

    def test_rejects_empty_manifest(self) -> None:
        with self.assertRaises(policy.ApprovalError):
            policy.canonical_manifest([])


class BlockApprovalTests(unittest.TestCase):
    def setUp(self) -> None:
        self.manifest = policy.canonical_manifest(
            ["confirm-protected-edit auth backend/PermissionLogic.cs"]
        )
        self.head = "a" * 40

    def test_verifies_exact_ticket_head_count_hash_and_entries(self) -> None:
        phrase = policy.block_phrase("DEV-71765", self.head, self.manifest)
        policy.verify_block_phrase(
            phrase,
            ticket="DEV-71765",
            head_sha=self.head,
            manifest=self.manifest,
        )

    def test_rejects_stale_head(self) -> None:
        phrase = policy.block_phrase("DEV-71765", self.head, self.manifest)
        with self.assertRaises(policy.ApprovalError):
            policy.verify_block_phrase(
                phrase,
                ticket="DEV-71765",
                head_sha="b" * 40,
                manifest=self.manifest,
            )

    def test_rejects_changed_entry_set(self) -> None:
        phrase = policy.block_phrase("DEV-71765", self.head, self.manifest)
        changed = policy.canonical_manifest(
            [
                "confirm-protected-edit auth backend/PermissionLogic.cs",
                "confirm-protected-edit package-versions backend/IdentityServer.csproj",
            ]
        )
        with self.assertRaises(policy.ApprovalError):
            policy.verify_block_phrase(
                phrase,
                ticket="DEV-71765",
                head_sha=self.head,
                manifest=changed,
            )

    def test_forbids_agent_config_in_block_mode(self) -> None:
        commands = (
            "confirm-protected-edit agent-config config/coder.md",
            "confirm-protected-edit auth .agents/agents/coder.md",
            "confirm-protected-edit auth .AGENTS/agents/coder.md",
            "confirm-protected-edit auth AGENTS.md",
            "confirm-protected-edit auth llm/AGENTS.md",
            "confirm-protected-edit auth subproject/.agents/agents/coder.md",
            "confirm-protected-edit auth subproject/.AGENTS/agents/coder.md",
        )
        for command in commands:
            manifest = policy.canonical_manifest([command])
            with self.subTest(command=command), self.assertRaises(policy.ApprovalError):
                policy.block_phrase("DEV-71765", self.head, manifest)

    def test_verify_current_head_appends_one_audit_record_per_entry(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            repository = Path(temporary_directory)
            git_dir = repository / ".git"
            git_dir.mkdir()
            (git_dir / "HEAD").write_text(self.head + "\n", encoding="utf-8")
            manifest = policy.canonical_manifest(
                [
                    "confirm-protected-edit auth backend/PermissionLogic.cs",
                    "confirm-protected-edit package-versions backend/IdentityServer.csproj",
                ]
            )
            phrase = policy.block_phrase("DEV-71765", self.head, manifest)
            resolved = policy.verify_current_and_audit(
                repository=repository,
                phrase=phrase,
                ticket="DEV-71765",
                manifest=manifest,
            )

            self.assertEqual(resolved, self.head)
            audit_log = policy.audit_log_path(repository)
            self.assertEqual(
                audit_log,
                repository.resolve() / ".git/protected-edit-approvals.jsonl",
            )
            records = [
                json.loads(line)
                for line in audit_log.read_text(encoding="utf-8").splitlines()
            ]
            self.assertEqual(len(records), 2)
            self.assertEqual(
                {record["path"] for record in records},
                {
                    "backend/PermissionLogic.cs",
                    "backend/IdentityServer.csproj",
                },
            )
            self.assertTrue(all(record["head_sha"] == self.head for record in records))

    def test_cli_rejects_head_and_audit_log_overrides(self) -> None:
        parser = policy.build_parser()
        rejected_options = (
            ("--head", "a" * 40),
            ("--audit-log", "AGENTS.md"),
            ("--audit-log", ".agents/state/audit.jsonl"),
            ("--audit-log", "backend/PermissionLogic.cs"),
            ("--audit-log", "/tmp/audit.jsonl"),
            ("--audit-log", "../audit.jsonl"),
            ("--audit-log", "linked/audit.jsonl"),
        )
        for option, value in rejected_options:
            with (
                self.subTest(option=option, value=value),
                contextlib.redirect_stderr(io.StringIO()),
                self.assertRaises(SystemExit),
            ):
                parser.parse_args(
                    [
                        "verify",
                        "--ticket",
                        "DEV-71765",
                        "--phrase",
                        "unused",
                        option,
                        value,
                    ]
                )

    def test_rejects_symlink_at_fixed_audit_path(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            repository = Path(temporary_directory)
            git_dir = repository / ".git"
            git_dir.mkdir()
            (git_dir / "HEAD").write_text(self.head + "\n", encoding="utf-8")
            agents = repository / "AGENTS.md"
            agents.write_text("protected\n", encoding="utf-8")
            policy.audit_log_path(repository).symlink_to(agents)
            phrase = policy.block_phrase("DEV-71765", self.head, self.manifest)

            with self.assertRaises(policy.ApprovalError):
                policy.verify_current_and_audit(
                    repository=repository,
                    phrase=phrase,
                    ticket="DEV-71765",
                    manifest=self.manifest,
                )

            self.assertEqual(agents.read_text(encoding="utf-8"), "protected\n")

    def test_rejects_fifo_at_fixed_audit_path_without_blocking(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            repository = Path(temporary_directory)
            git_dir = repository / ".git"
            git_dir.mkdir()
            (git_dir / "HEAD").write_text(self.head + "\n", encoding="utf-8")
            os.mkfifo(policy.audit_log_path(repository))
            phrase = policy.block_phrase("DEV-71765", self.head, self.manifest)

            completed = subprocess.run(
                [
                    sys.executable,
                    str(ROOT / ".ai/bin/protected_edit_approval.py"),
                    "verify",
                    "--ticket",
                    "DEV-71765",
                    "--repository",
                    str(repository),
                    "--phrase",
                    phrase,
                ],
                input=self.manifest.content,
                capture_output=True,
                timeout=1,
            )

            self.assertEqual(completed.returncode, 1)
            self.assertIn(b"FAIL: unable to open approval audit", completed.stderr)

    def test_rejects_git_metadata_manifest_targets(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            repository = Path(temporary_directory)
            git_dir = repository / ".git"
            git_dir.mkdir()
            (git_dir / "HEAD").write_text(self.head + "\n", encoding="utf-8")
            for path in (
                ".git",
                ".git/protected-edit-approvals.jsonl",
                ".GIT",
                ".GIT/HEAD",
            ):
                manifest = policy.canonical_manifest(
                    [f"confirm-protected-edit auth {path}"]
                )
                with self.subTest(path=path), self.assertRaises(policy.ApprovalError):
                    policy.validate_manifest_paths(repository, manifest)

    def test_rejects_git_metadata_manifest_targets_in_linked_worktree(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            repository = root / "worktree"
            repository.mkdir()
            git_dir = root / "common/worktrees/feature"
            git_dir.mkdir(parents=True)
            (repository / ".git").write_text(
                f"gitdir: {git_dir}\n",
                encoding="utf-8",
            )
            (git_dir / "HEAD").write_text(self.head + "\n", encoding="utf-8")
            for path in (
                ".git",
                ".git/protected-edit-approvals.jsonl",
                ".GIT",
                ".GIT/HEAD",
            ):
                manifest = policy.canonical_manifest(
                    [f"confirm-protected-edit auth {path}"]
                )
                with self.subTest(path=path), self.assertRaises(policy.ApprovalError):
                    policy.validate_manifest_paths(repository, manifest)

    def test_rejects_linked_worktree_git_metadata_aliases(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            repository = root / "worktree"
            repository.mkdir()
            git_dir = root / "common/worktrees/feature"
            git_dir.mkdir(parents=True)
            marker = repository / ".git"
            marker.write_text(f"gitdir: {git_dir}\n", encoding="utf-8")
            head = git_dir / "HEAD"
            head.write_text(self.head + "\n", encoding="utf-8")
            (repository / "metadata-link").symlink_to(".git")
            os.link(marker, repository / "metadata-hardlink")
            os.link(head, repository / "head-hardlink")
            (repository / "inside-target").write_text("target\n", encoding="utf-8")
            (repository / "inside-link").symlink_to("inside-target")

            for path in (
                "metadata-link",
                "metadata-hardlink",
                "head-hardlink",
                "inside-link",
            ):
                manifest = policy.canonical_manifest(
                    [f"confirm-protected-edit auth {path}"]
                )
                with self.subTest(path=path), self.assertRaises(policy.ApprovalError):
                    policy.validate_manifest_paths(repository, manifest)

    def test_rejects_symlink_escape_from_repository(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            repository = root / "repository"
            outside = root / "outside"
            repository.mkdir()
            outside.mkdir()
            (repository / "linked").symlink_to(outside, target_is_directory=True)
            manifest = policy.canonical_manifest(
                ["confirm-protected-edit auth linked/outside.cs"]
            )

            with self.assertRaises(policy.ApprovalError):
                policy.validate_manifest_paths(repository, manifest)


class GitHeadTests(unittest.TestCase):
    def test_reads_direct_head(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            repository = Path(temporary_directory)
            git_dir = repository / ".git"
            git_dir.mkdir()
            expected = "a" * 40
            (git_dir / "HEAD").write_text(expected + "\n", encoding="utf-8")
            self.assertEqual(policy.current_head(repository), expected)

    def test_reads_worktree_head_from_common_directory(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            repository = root / "worktree"
            repository.mkdir()
            common = root / "common"
            git_dir = common / "worktrees/feature"
            git_dir.mkdir(parents=True)
            (repository / ".git").write_text(
                f"gitdir: {git_dir}\n",
                encoding="utf-8",
            )
            (git_dir / "HEAD").write_text("ref: refs/heads/feature\n", encoding="utf-8")
            (git_dir / "commondir").write_text("../..\n", encoding="utf-8")
            reference = common / "refs/heads/feature"
            reference.parent.mkdir(parents=True)
            expected = "b" * 40
            reference.write_text(expected + "\n", encoding="utf-8")
            self.assertEqual(policy.current_head(repository), expected)


if __name__ == "__main__":
    unittest.main()
