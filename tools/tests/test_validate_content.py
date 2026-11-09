"""Tests for tools/validate_content.py.

Run from the repository root with the project's virtualenv:
    .venv/bin/python -m unittest -v

Each directory under fixtures/valid/ holds a content/ tree that must pass.
Each directory under fixtures/invalid/ holds a content/ tree that must fail,
and an expected.txt whose lines are the beginnings of the exact error lines
the validator must print, one per expected error and no others.
"""

from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

TESTS_DIR = Path(__file__).resolve().parent
REPO_ROOT = TESTS_DIR.parent.parent
VALIDATOR = REPO_ROOT / "tools" / "validate_content.py"
FIXTURES = TESTS_DIR / "fixtures"


def run_validator(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(VALIDATOR), *args],
        cwd=str(REPO_ROOT),
        capture_output=True,
        text=True,
    )


def error_lines(output: str) -> list:
    return [line for line in output.splitlines()
            if not line.startswith("content validation ")]


class ValidFixtures(unittest.TestCase):
    def test_valid_fixtures_pass(self) -> None:
        cases = sorted(p for p in (FIXTURES / "valid").iterdir() if p.is_dir())
        self.assertTrue(cases, "no valid fixtures found")
        for case in cases:
            with self.subTest(case=case.name):
                result = run_validator("--content-dir", str(case / "content"))
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(result.stdout.strip(), "content validation passed")

    def test_repository_content_passes(self) -> None:
        result = run_validator()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_missing_content_dir_fails(self) -> None:
        result = run_validator("--content-dir", str(FIXTURES / "does-not-exist"))
        self.assertEqual(result.returncode, 1)
        self.assertIn("content directory does not exist", result.stdout)


class InvalidFixtures(unittest.TestCase):
    def test_invalid_fixtures_fail_with_expected_errors(self) -> None:
        cases = sorted(p for p in (FIXTURES / "invalid").iterdir() if p.is_dir())
        self.assertTrue(cases, "no invalid fixtures found")
        for case in cases:
            with self.subTest(case=case.name):
                expected = (case / "expected.txt").read_text(encoding="utf-8").splitlines()
                result = run_validator("--content-dir", str(case / "content"))
                self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
                lines = error_lines(result.stdout)
                self.assertEqual(len(lines), len(expected),
                                 "expected %d error(s), got:\n%s"
                                 % (len(expected), result.stdout))
                for want in expected:
                    self.assertTrue(any(line.startswith(want) for line in lines),
                                    "missing %r in:\n%s" % (want, result.stdout))
                self.assertIn("content validation failed", result.stdout)


if __name__ == "__main__":
    unittest.main()
