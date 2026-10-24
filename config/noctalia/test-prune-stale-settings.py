import pathlib
import subprocess
import sys
import tempfile
import tomllib
import unittest


SCRIPT = pathlib.Path(__file__).with_name("prune-stale-settings.py")
TIMER = "desktop-widget-0000000000000003"
SETTINGS = f'''launcher_session_search = true
[desktop_widgets]
widget_order = ["clock", "{TIMER}"]
[desktop_widgets.widget.clock]
type = "clock"
[desktop_widgets.widget.{TIMER}]
type = "noctalia/timer:desktop"
[desktop_widgets.widget.{TIMER}.settings]
duration = 2700
[theme]
mode = "light"
[plugin_settings."noctalia/screen_recorder"]
obsolete = true
'''


class CleanupTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.path = pathlib.Path(directory.name) / "settings.toml"

    def run_cleanup(self):
        return subprocess.run([sys.executable, SCRIPT, self.path], capture_output=True)

    def test_cleanup_with_existing_v5_backup(self):
        self.path.write_text(SETTINGS)
        old_backup = self.path.with_suffix(".toml.before-noctalia-v5-cleanup")
        old_backup.write_text("previous backup")
        self.assertEqual(self.run_cleanup().returncode, 0)
        cleaned = tomllib.loads(self.path.read_text())
        self.assertEqual(cleaned["desktop_widgets"]["widget_order"], ["clock"])
        self.assertEqual(cleaned["desktop_widgets"]["widget"], {"clock": {"type": "clock"}})
        self.assertEqual(cleaned["theme"], {"mode": "light"})
        self.assertNotIn("launcher_session_search", cleaned)
        self.assertNotIn("plugin_settings", cleaned)
        self.assertEqual(old_backup.read_text(), "previous backup")
        backup = self.path.with_suffix(".toml.before-noctalia-timer-cleanup")
        self.assertEqual(backup.read_text(), SETTINGS)
        before = self.path.stat().st_mtime_ns
        self.assertEqual(self.run_cleanup().returncode, 0)
        self.assertEqual(self.path.stat().st_mtime_ns, before)
        self.assertEqual(backup.read_text(), SETTINGS)

    def test_preserves_supported_widget_with_same_id(self):
        settings = SETTINGS.replace("noctalia/timer:desktop", "clock")
        self.path.write_text(settings)
        self.assertEqual(self.run_cleanup().returncode, 0)
        cleaned = tomllib.loads(self.path.read_text())
        self.assertIn(TIMER, cleaned["desktop_widgets"]["widget"])
        self.assertIn(TIMER, cleaned["desktop_widgets"]["widget_order"])

    def test_missing_or_invalid_file(self):
        self.assertEqual(self.run_cleanup().returncode, 0)
        self.assertFalse(self.path.exists())
        self.path.write_text("[invalid")
        self.assertNotEqual(self.run_cleanup().returncode, 0)
        self.assertEqual(self.path.read_text(), "[invalid")
        self.assertEqual(list(self.path.parent.iterdir()), [self.path])


if __name__ == "__main__":
    unittest.main()
