"""Exercise the real launcher with a fake Niri IPC endpoint; never touch the desktop."""

import json
import os
from pathlib import Path
import subprocess
import shutil
import tempfile
import unittest


BASH = shutil.which("bash")
SCRIPT = Path(__file__).resolve().parents[2] / "config/niri/scripts/focus-or-launch"


class FocusOrLaunch(unittest.TestCase):
    def run_script(self, windows, *options, ipc_status=0):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "windows.json").write_text(json.dumps(windows))
            niri = root / "niri"
            niri.write_text(f'#!{BASH}\n' + '''if [[ $1 == msg && $2 == --json && $3 == windows ]]; then
    cat "$TEST_ROOT/windows.json"
    exit "$IPC_STATUS"
fi
printf '%s\\n' "$*" >> "$TEST_ROOT/actions"
''')
            niri.chmod(0o755)
            launch = root / "launch"
            launch.write_text(f'#!{BASH}\n' + 'printf "%s\\n" "$*" > "$TEST_ROOT/launched"\n')
            launch.chmod(0o755)
            result = subprocess.run(
                [BASH, str(SCRIPT), "^kitty$", *options, "--", str(launch), "argument with spaces"],
                env={**os.environ, "PATH": f"{root}:{os.environ['PATH']}",
                     "TEST_ROOT": str(root), "IPC_STATUS": str(ipc_status)},
                text=True, capture_output=True,
            )
            return (result.returncode,
                    (root / "actions").read_text() if (root / "actions").exists() else "",
                    (root / "launched").read_text() if (root / "launched").exists() else "")

    def test_launch_when_absent(self):
        self.assertEqual(self.run_script([]), (0, "", "argument with spaces\n"))

    def test_focused_persistent_app_is_not_closed(self):
        self.assertEqual(self.run_script([
            {"id": 1, "app_id": "kitty", "is_focused": True},
        ]), (0, "msg action focus-window --id 1\n", ""))

    def test_close_is_explicit_and_title_scoped(self):
        windows = [
            {"id": 1, "app_id": "kitty", "title": "editor", "is_focused": True},
            {"id": 2, "app_id": "kitty", "title": "dropdown-term", "is_focused": False},
        ]
        options = ("--title", "^dropdown-term$", "--close-focused")
        self.assertEqual(self.run_script(windows, *options), (0, "msg action focus-window --id 2\n", ""))
        windows[0]["is_focused"], windows[1]["is_focused"] = False, True
        self.assertEqual(self.run_script(windows, *options), (0, "msg action close-window --id 2\n", ""))

    def test_multiple_windows_prefer_focused_then_recent(self):
        windows = [
            {"id": 1, "app_id": "kitty", "is_focused": False,
             "focus_timestamp": {"secs": 2, "nanos": 0}},
            {"id": 2, "app_id": "kitty", "is_focused": False,
             "focus_timestamp": {"secs": 3, "nanos": 0}},
        ]
        self.assertEqual(self.run_script(windows)[1], "msg action focus-window --id 2\n")
        windows[0]["is_focused"] = True
        self.assertEqual(self.run_script(windows)[1], "msg action focus-window --id 1\n")

    def test_ipc_failure_does_not_launch_a_duplicate(self):
        code, actions, launched = self.run_script([], ipc_status=1)
        self.assertNotEqual(code, 0)
        self.assertEqual((actions, launched), ("", ""))

    def test_ambiguous_toggle_flag_is_rejected(self):
        self.assertEqual(self.run_script([], "--toggle")[0], 2)


if __name__ == "__main__":
    unittest.main()
