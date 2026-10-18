#!/usr/bin/env python3
"""Run the actual deployment guard against disposable identity metadata only."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[2] / "modules/deployment/preflight.sh"


class Preflight(unittest.TestCase):
    def run_guard(self, root, available=True):
        script = (
            SCRIPT.read_text()
            .replace("@available@", str(available).lower())
            .replace("@ciphertext@", "/dev/null")
        )
        return subprocess.run(
            ["bash", "-c", script, "preflight", str(root)], capture_output=True
        )

    def test_unavailable_material_refuses_even_with_old_identity(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertNotEqual(self.run_guard(d, False).returncode, 0)

    def test_missing_identity_refuses(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertNotEqual(self.run_guard(d).returncode, 0)

    def test_unsafe_permissions_and_symlink_refuse(self):
        with tempfile.TemporaryDirectory() as d:
            key = Path(d) / "var/lib/sops-nix/key.txt"
            key.parent.mkdir(parents=True)
            key.write_text("fixture only; not a private key")
            key.chmod(0o644)
            self.assertNotEqual(self.run_guard(d).returncode, 0)
            original = key.rename(key.with_suffix(".fixture"))
            key.symlink_to(original)
            self.assertNotEqual(self.run_guard(d).returncode, 0)

    @unittest.skipUnless(os.geteuid() == 0, "success requires root-owned fixture")
    def test_malformed_identity_refuses(self):
        with tempfile.TemporaryDirectory() as d:
            key = Path(d) / "var/lib/sops-nix/key.txt"
            key.parent.mkdir(parents=True)
            key.write_text("fixture only; not a private key")
            key.chmod(0o600)
            self.assertNotEqual(self.run_guard(d).returncode, 0)


if __name__ == "__main__":
    unittest.main()
