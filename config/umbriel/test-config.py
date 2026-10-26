#!/usr/bin/env python3
"""Regression checks for Niri routing, scratchpads, bindings, and app reuse."""

import importlib.machinery
import importlib.util
import json
from pathlib import Path
import re
import subprocess
import sys
import tomllib
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent


def load(name):
    return tomllib.loads((ROOT / name).read_text())


def resolve(app_id, title):
    result = {}
    for rule in load("rules.toml")["window_rule"] + load("scratchpads.toml")["window_rule"]:
        if all(re.search(pattern, {"app_id": app_id, "title": title}[key], re.ASCII)
               for key, pattern in rule["match"].items()):
            result.update({k: v for k, v in rule.items() if k != "match"})
    return result


loader = importlib.machinery.SourceFileLoader("focus", str(ROOT / "scripts/focus-or-launch"))
spec = importlib.util.spec_from_loader(loader.name, loader)
focus = importlib.util.module_from_spec(spec)
loader.exec_module(focus)


class ConfigTests(unittest.TestCase):
    def test_main_window_routing(self):
        cases = [
            ("zen", "Example — Zen", "browser"),
            ("firefox", "Example", "browser"),
            ("md.obsidian.Obsidian", "My vault", "notes"),
            ("anki", "Decks", "anki"),
            ("orca", "Orca", "code"),
            ("kitty", "editor", "code"),
            ("kitty", "project-session", "code"),
            ("code", "Project", "code"),
            ("steam", "Steam", "gaming"),
            ("steamwebhelper", "Steam", "gaming"),
            ("PrismLauncher", "Prism Launcher 10.0.0", "gaming"),
            ("obs", "OBS Studio", "gaming"),
            ("org.telegram.desktop", "Telegram (2)", "chats"),
            ("org.telegram.desktop", "\u200e\u2068Alice\u2069", "chats"),
            ("vesktop", "Discord | Friends", "chats"),
        ]
        for app, title, workspace in cases:
            with self.subTest(app=app, title=title):
                self.assertEqual(resolve(app, title)["default_workspace"], workspace)

    def test_dialogs_do_not_follow_main_workspace_rules(self):
        cases = [
            ("zen", "Delete Space?"), ("zen", "Picture-in-Picture"),
            ("md.obsidian.Obsidian", "Settings - My vault"),
            ("md.obsidian.Obsidian", "Community plugins - My vault"),
            ("anki", "Add"), ("anki", "Настройки"), ("anki", "Настройки - Anki"),
            ("steam", "Sign in to Steam"), ("steamwebhelper", "Steam Settings"),
            ("PrismLauncher", "Settings — Prism Launcher 10.0.0"),
            ("obs", "Settings"), ("obs", "Plugin Manager"),
            ("org.telegram.desktop", "Media viewer"),
            ("vesktop", "Alice"),
        ]
        for app, title in cases:
            with self.subTest(app=app, title=title):
                rule = resolve(app, title)
                self.assertNotIn("default_workspace", rule)
                self.assertTrue(rule["default_floating"])
                self.assertFalse(rule.get("default_maximize_to_edges", False))

    def test_games_and_scratchpads(self):
        self.assertTrue(resolve("steam_app_730", "Counter-Strike 2")["default_fullscreen"])
        for app, title, pad in [("sonora", "Music", "music"),
                                ("kitty", "dropdown-term", "terminal"),
                                ("kitty", "file-manager", "files")]:
            with self.subTest(pad=pad):
                self.assertEqual(resolve(app, title)["default_scratchpad"], pad)
        self.assertNotIn("default_scratchpad", resolve("kitty", "ordinary terminal"))

    def test_all_niri_chords_are_present(self):
        source = (ROOT.parent / "niri/sub/binds.kdl").read_text()
        chords = {c.replace("WheelScroll", "Wheel") for c in
                  re.findall(r"^\s*(\S+)\s+[^\n]*\{", source, re.M) if c != "binds"}
        self.assertFalse(chords - load("binds.toml")["keybinds"].keys())

    def test_reuses_focused_window_before_other_visible_windows(self):
        windows = [{"id": "other", "app_id": "zen", "visible": True},
                   {"id": "focused", "app_id": "zen", "visible": True, "active": True}]
        with patch.object(sys, "argv", ["focus", "^zen$", "--", "zen-beta"]), \
             patch.object(focus.subprocess, "check_output", return_value=json.dumps(windows)), \
             patch.object(focus.subprocess, "run") as run, patch.object(focus.os, "execvp") as launch:
            focus.main()
            run.assert_called_once_with(["umbriel", "msg", "window-focus-warp:focused"], check=True)
            launch.assert_not_called()

    def test_launches_only_when_no_match_exists(self):
        with patch.object(sys, "argv", ["focus", "^zen$", "--", "zen-beta", "--new-window"]), \
             patch.object(focus.subprocess, "check_output", return_value="[]"), \
             patch.object(focus.os, "execvp") as launch:
            focus.main()
            launch.assert_called_once_with("zen-beta", ["zen-beta", "--new-window"])

    def test_ipc_failure_does_not_launch_a_duplicate(self):
        with patch.object(sys, "argv", ["focus", "^zen$", "--", "zen-beta"]), \
             patch.object(focus.subprocess, "check_output", side_effect=subprocess.CalledProcessError(1, "umbriel")), \
             patch.object(focus.os, "execvp") as launch:
            with self.assertRaises(subprocess.CalledProcessError):
                focus.main()
            launch.assert_not_called()


if __name__ == "__main__":
    unittest.main()
