#!/usr/bin/env python3
"""Policy matching is checked against encrypted-document recipient metadata only."""

from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[2] / "lib/check-sops-policy.py"


class Policy(unittest.TestCase):
    def run_policy(self, policy, host="fixture"):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / "cipher.yaml").write_text(
                "sops:\n  age:\n    - recipient: fixture-admin\n    - recipient: fixture-host\n"
            )
            (root / "policy.yaml").write_text(policy)
            return subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    str(root / "cipher.yaml"),
                    str(root / "policy.yaml"),
                    host,
                ],
                capture_output=True,
            )

    def test_matching_host_policy_accepts_same_recipients(self):
        result = self.run_policy(
            "creation_rules:\n  - path_regex: secrets/hosts/fixture\\.yaml$\n    age: fixture-host,fixture-admin\n"
        )
        self.assertEqual(result.returncode, 0, result.stderr.decode())

    def test_recipient_scope_mismatch_refuses(self):
        for recipients in ["fixture-admin", "fixture-host,fixture-admin,another-host"]:
            result = self.run_policy("creation_rules:\n  - age: " + recipients + "\n")
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn(b"fixture-admin", result.stderr)

    def test_wrong_host_and_malformed_policy_refuse(self):
        for policy in [
            "creation_rules: null",
            "creation_rules: [1]",
            "invalid: [",
            "creation_rules:\n  - path_regex: other-host\\.yaml$\n    age: fixture-host,fixture-admin\n",
        ]:
            self.assertNotEqual(self.run_policy(policy).returncode, 0)


if __name__ == "__main__":
    unittest.main()
