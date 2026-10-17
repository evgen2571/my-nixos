"""Check main-window title signatures against sanitized PC observations."""

from pathlib import Path
import re
import unittest


RULES = Path(__file__).resolve().parents[2] / "config/niri/sub/rules/apps"


class WindowTitles(unittest.TestCase):
    def check_titles(self, app, cases):
        source = (RULES / f"{app}.kdl").read_text()
        # The first title-qualified match in each owner identifies main windows.
        match = re.search(r'match app-id=.* title=r#"([^"]+)"#', source)
        self.assertIsNotNone(match, f"{app}: missing main-window title signature")
        pattern = re.compile(match[1])
        for title, is_main in cases:
            with self.subTest(app=app, title=title):
                self.assertEqual(bool(pattern.search(title)), is_main)
        # Main and auxiliary rules must agree about the routing boundary.
        self.assertIn(f'exclude title=r#"{match[1]}"#', source)

    def test_telegram(self):
        self.check_titles("telegram", [
            ("Telegram", True),
            ("Telegram (28)", True),
            ("\u200e\u2068Test group\u2069", True),
            ("\u200e\u2068Test group\u2069 – (31)", True),
            ("(3) \u200e\u2068Test group\u2069 – (31)", True),
            ("\u200e\u2068Test group\u2069 @ \u200e\u2068Account\u2069 (31)", True),
            ("Test group", False),
            ("Test contact", False),
            ("Media viewer", False),
        ])

    def test_vesktop(self):
        self.check_titles("vesktop", [
            ("vesktop", True),
            ("Vesktop", True),
            ("Discord", True),
            ("(83) Discord | Friends", True),
            ("(83) Discord | #general | Test server", True),
            ("Discord | General | Test server", True),
            ("General", False),
            ("Another voice channel", False),
            ("Discord Popout", False),
        ])


if __name__ == "__main__":
    unittest.main()
