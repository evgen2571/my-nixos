"""Check binding policy and opening-rule classification without a running desktop.

Niri validates the full KDL syntax separately. This only interprets the app-id
and title matchers used by the opening rules, including their OR/AND semantics.
"""

import json
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]
CONFIG = ROOT / "config/niri"


def expand(path):
    return re.sub(r'^include "([^"]+)"$',
                  lambda match: expand(path.parent / match[1]),
                  path.read_text(), flags=re.MULTILINE)


def matches(line, app_id, title):
    fields = re.findall(r'(app-id|title)=(?:r#"(.*?)"#|r"(.*?)"|("(?:[^"\\]|\\.)*"))', line)
    assert fields, f"Unrecognized rule matcher: {line}"
    return all(re.search(raw or short or json.loads(quoted),
                         app_id if field == "app-id" else title)
               for field, raw, short, quoted in fields)


def properties(app_id, title):
    result = {}
    for body in re.findall(r'^window-rule \{\n(.*?)^\}',
                           expand(CONFIG / "sub/rules/common.kdl"), re.MULTILINE | re.DOTALL):
        includes = re.findall(r'^\s*match (.+)$', body, re.MULTILINE)
        excludes = re.findall(r'^\s*exclude (.+)$', body, re.MULTILINE)
        if (not includes or any(matches(line, app_id, title) for line in includes)) and not any(
            matches(line, app_id, title) for line in excludes
        ):
            result.update(re.findall(r'^\s*(open-[\w-]+) (.+)$', body, re.MULTILINE))
            result.update(re.findall(r'^\s*(default-floating-position) (.+)$', body, re.MULTILINE))
            result.update(re.findall(r'^\s*(default-(?:column-width|window-height)) \{ (.*?) \}',
                                     body, re.MULTILINE))
    return result


class Configuration(unittest.TestCase):
    def test_games_open_fullscreen_on_gaming_workspace(self):
        for app in ("steam_app_730", "steam_app_570", "gamescope", "cs2",
                    "Minecraft", "minecraft", "osu!"):
            with self.subTest(app=app):
                rule = properties(app, "Game")
                self.assertEqual(rule.get("open-fullscreen"), "true")
                self.assertEqual(rule.get("open-on-workspace"), '"gaming"')
        for app in ("steam", "steamwebhelper", "org.prismlauncher.PrismLauncher",
                    "PrismLauncher", "lutris"):
            with self.subTest(app=app):
                rule = properties(app, "Launcher")
                self.assertEqual(rule["open-maximized-to-edges"], "true")
                self.assertEqual(rule["open-on-workspace"], '"gaming"')
                self.assertNotIn("open-fullscreen", rule)
        for app in ("steam_app_", "steam_app_730extra", "other_steam_app_730", "other"):
            with self.subTest(app=app):
                rule = properties(app, "Minecraft")
                self.assertNotIn("open-fullscreen", rule)
                self.assertNotIn("open-on-workspace", rule)

    def test_gaming_workspace_position(self):
        for name, output, index in [("workspaces.kdl", "HDMI-A-1", 3),
                                    ("workspaces-pc.kdl", "HDMI-A-1", 3),
                                    ("workspaces-laptop.kdl", "eDP-1", 5)]:
            with self.subTest(profile=name):
                source = (CONFIG / "sub" / name).read_text()
                workspaces = re.findall(r'workspace "([^"]+)" \{\n(.*?)^\}',
                                        source, re.MULTILINE | re.DOTALL)
                on_output = [workspace for workspace, body in workspaces
                             if f'open-on-output "{output}"' in body]
                self.assertEqual(on_output.index("gaming") + 1, index)

    def test_observed_floating_windows(self):
        for app, title, width, height in [
            ("steam", "Sign in to Steam", "0.40", "0.55"),
            ("com.obsproject.Studio", "Add Scene", "0.35", "0.30"),
            ("com.obsproject.Studio", "Plugin Manager", "0.65", "0.70"),
            ("org.kde.ark", "Ark", "0.70", "0.70"),
        ]:
            with self.subTest(app=app, title=title):
                rule = properties(app, title)
                self.assertEqual(rule.get("open-floating"), "true")
                self.assertEqual(rule.get("open-focused"), "true")
                self.assertEqual(rule.get("open-maximized-to-edges"), "false")
                self.assertEqual(rule["default-column-width"], f"proportion {width};")
                self.assertEqual(rule["default-window-height"], f"proportion {height};")
                self.assertNotIn("open-on-workspace", rule)
                self.assertNotIn("open-on-output", rule)
                # Niri centers new floating windows when no position is specified.
                self.assertNotIn("default-floating-position", rule)
                self.assertNotIn("open-floating", properties("other", title))

    def test_zen_windows_and_picture_in_picture(self):
        google = "Sign in - Google Accounts — Zen Browser Private Browsing"
        for app, title in [
            ("zen-beta", google),
            ("zen-beta", "Sign in to Apple\u00a0Account — Zen Browser Private Browsing"),
            ("zen-beta", "Sign in to Apple Account — Zen Browser Private Browsing"),
            ("zen-beta", "Example page — Zen Browser"),
            ("zen-beta", "Example page — Zen Browser Private Browsing"),
            ("zen-beta", "Zen Browser Private Browsing"),
            ("zen-beta", "Sign in - Google Accounts — Zen Browser"),
            ("zen-beta", "Sign in to Apple Account — Zen Browser"),
            ("zen-beta", google + " extra"),
            ("zen-beta", "Example - " + google),
            ("zen", google),
            ("firefox", google),
            ("chromium", google),
        ]:
            with self.subTest(app=app, title=title):
                rule = properties(app, title)
                self.assertEqual(rule["open-on-workspace"], '"browser"')
                self.assertEqual(rule["open-maximized-to-edges"], "true")
                self.assertNotIn("open-floating", rule)
        for title in ("Picture-in-Picture", "Picture in picture"):
            rule = properties("zen-beta", title)
            self.assertEqual(rule["open-floating"], "true")
            self.assertEqual(rule["open-focused"], "false")
            self.assertNotIn("open-on-workspace", rule)

    def test_zen_delete_space_dialog(self):
        for app in ("zen-beta", "zen"):
            with self.subTest(app=app):
                rule = properties(app, "Delete Space?")
                self.assertEqual(rule.get("open-floating"), "true")
                self.assertEqual(rule.get("open-maximized-to-edges"), "false")
                self.assertNotIn("open-on-workspace", rule)
                # New floating windows are centered by default.
                self.assertNotIn("default-floating-position", rule)
        for app, title in (("other", "Delete Space?"), ("zen-beta", "Delete Space? — Zen Browser")):
            self.assertNotIn("open-floating", properties(app, title))

    def test_steam_and_obs_existing_windows(self):
        for app in ("steam", "steamwebhelper"):
            for title in ("Steam Settings", "Friends List", "Chat", "Properties",
                          "Downloads", "Special Offers"):
                with self.subTest(app=app, title=title):
                    rule = properties(app, title)
                    self.assertEqual(rule["open-floating"], "true")
                    self.assertEqual(rule["default-column-width"], "proportion 0.58;")
                    self.assertEqual(rule["default-window-height"], "proportion 0.65;")
                    self.assertNotIn("open-on-workspace", rule)
        for app in ("com.obsproject.Studio", "obs"):
            rule = properties(app, "Settings")
            self.assertEqual(rule["open-floating"], "true")
            self.assertEqual(rule["default-column-width"], "proportion 0.60;")
            self.assertEqual(rule["default-window-height"], "proportion 0.75;")
            self.assertNotIn("open-on-workspace", rule)
        for app, title in [("steam", "Sign in to Steam extra"),
                           ("steamwebhelper", "Sign in to Steam"),
                           ("com.obsproject.Studio", "Add Scene extra"),
                           ("com.obsproject.Studio", "Plugin Manager extra"),
                           ("com.obsproject.Studio", "Projector - Preview")]:
            with self.subTest(app=app, title=title):
                rule = properties(app, title)
                self.assertEqual(rule["open-on-workspace"], '"gaming"')
                self.assertEqual(rule["open-maximized-to-edges"], "true")
                self.assertNotIn("open-floating", rule)
                self.assertNotIn("open-fullscreen", rule)

    def test_ark_and_krita_native_dialogs(self):
        for app, title in [("org.kde.ark", "Extract — Ark"),
                           ("org.kde.ark", "Ark extra"), ("krita", "Krita")]:
            with self.subTest(app=app, title=title):
                rule = properties(app, title)
                for option in ("open-floating", "open-maximized", "open-maximized-to-edges",
                               "open-on-workspace", "default-column-width", "default-window-height"):
                    self.assertNotIn(option, rule)

    def test_orca_observed_main_window_only(self):
        rule = properties("orca", "Orca")
        self.assertEqual(rule["open-on-workspace"], '"code"')
        self.assertEqual(rule["open-maximized-to-edges"], "true")
        self.assertNotIn("open-floating", rule)
        for app, title in [("orca", "Settings"), ("orca", "Example project"),
                           ("orca", "Orca extra"), ("other", "Orca")]:
            with self.subTest(app=app, title=title):
                rule = properties(app, title)
                self.assertNotIn("open-on-workspace", rule)
                self.assertNotIn("open-maximized-to-edges", rule)

    def test_wayscriber_daemon_startup(self):
        startup = (CONFIG / "sub/startup.kdl").read_text().splitlines()
        self.assertEqual(startup.count('spawn-at-startup "wayscriber" "--daemon"'), 1)

    def test_qimgv_floats_without_a_fixed_position(self):
        rule = properties("qimgv", "example.png - qimgv")
        self.assertEqual(rule["open-floating"], "true")
        self.assertEqual(rule["open-focused"], "true")
        self.assertEqual(rule["open-fullscreen"], "false")
        self.assertNotIn("open-on-workspace", rule)
        self.assertEqual(rule["default-column-width"], "proportion 0.70;")
        self.assertEqual(rule["default-window-height"], "proportion 0.70;")
        body = next(body for body in re.findall(r'^window-rule \{\n(.*?)^\}',
                    expand(CONFIG / "sub/rules/common.kdl"), re.MULTILINE | re.DOTALL)
                    if 'app-id=r#"^qimgv$"#' in body)
        self.assertNotIn("default-floating-position", body)
        self.assertNotIn("open-floating", properties("other", "example.png - qimgv"))

    def test_dolphin_dialog_sizes(self):
        for title in ("Configure — Dolphin", "Configure Language — Dolphin",
                      "Configure Toolbars — Dolphin", "Properties for example.jpg — Dolphin"):
            with self.subTest(title=title):
                rule = properties("org.kde.dolphin", title)
                self.assertEqual(rule["open-floating"], "true")
                self.assertEqual(rule["default-column-width"], "proportion 0.42;")
                self.assertEqual(rule["default-window-height"], "proportion 0.55;")
                self.assertNotIn("open-on-workspace", rule)
                self.assertNotIn("default-column-width", properties("other", title))
        for app, title in [("org.kde.dolphin", "Wallpapers — Dolphin"),
                           ("org.kde.dolphin", "Configure — Dolphin — Dolphin"),
                           ("thunar", "Configure — Dolphin")]:
            rule = properties(app, title)
            self.assertEqual(rule["default-column-width"], "proportion 0.62;")
            self.assertEqual(rule["default-window-height"], "proportion 0.70;")

    def test_navigation_and_conflicts(self):
        bindings = {}
        for key, action in re.findall(r'^\s*(\S+) [^\n{]*\{ (.*?) \}$',
                                      (CONFIG / "sub/binds.kdl").read_text(), re.MULTILINE):
            normalized = tuple(sorted(key.split("+")))
            self.assertNotIn(normalized, bindings, f"Duplicate binding: {key}")
            bindings[normalized] = action

        expected = {
            "Mod+Shift+D": 'spawn "wayscriber" "--daemon-toggle";',
            "Mod+H": "focus-column-or-monitor-left;",
            "Mod+L": "focus-column-or-monitor-right;",
            "Mod+J": "focus-window-or-workspace-down;",
            "Mod+K": "focus-window-or-workspace-up;",
            "Mod+Shift+H": "move-column-left-or-to-monitor-left;",
            "Mod+Shift+L": "move-column-right-or-to-monitor-right;",
            "Mod+Shift+J": "move-window-to-workspace-down;",
            "Mod+Shift+K": "move-window-to-workspace-up;",
            "Mod+Ctrl+H": "focus-monitor-left;",
            "Mod+Ctrl+L": "focus-monitor-right;",
            "Mod+Ctrl+J": "focus-workspace-down;",
            "Mod+Ctrl+K": "focus-workspace-up;",
            "Mod+Alt+H": 'set-column-width "-5%";',
            "Mod+Alt+L": 'set-column-width "+5%";',
            "Mod+Alt+J": 'set-window-height "-5%";',
            "Mod+Alt+K": 'set-window-height "+5%";',
            "Mod+Ctrl+Shift+H": "move-column-to-monitor-left;",
            "Mod+Ctrl+Shift+L": "move-column-to-monitor-right;",
            "Mod+Ctrl+Shift+J": "move-column-to-workspace-down;",
            "Mod+Ctrl+Shift+K": "move-column-to-workspace-up;",
            "Mod+R": "switch-preset-column-width;",
            "Mod+Shift+R": "switch-preset-window-height;",
            "Mod+Ctrl+R": "reset-window-height;",
            "Mod+Shift+P": 'spawn "noctalia" "msg" "session" "lock-and-suspend";',
        }
        for key, action in expected.items():
            with self.subTest(key=key):
                self.assertEqual(bindings[tuple(sorted(key.split("+")))], action)
        for key in "HJKL":
            self.assertNotIn(tuple(sorted(f"Mod+Ctrl+Alt+{key}".split("+"))), bindings)
        for key in ("U", "I"):
            for modifier in ("Mod", "Mod+Ctrl", "Mod+Shift"):
                self.assertNotIn(tuple(sorted(f"{modifier}+{key}".split("+"))), bindings)
        for arrow, letter in {"Left": "H", "Down": "J", "Up": "K", "Right": "L"}.items():
            self.assertNotIn(tuple(sorted(f"Mod+Ctrl+{arrow}".split("+"))), bindings)
            for modifier in ("Mod", "Mod+Shift", "Mod+Alt"):
                self.assertEqual(bindings[tuple(sorted(f"{modifier}+{arrow}".split("+")))],
                                 bindings[tuple(sorted(f"{modifier}+{letter}".split("+")))])

    def test_noctalia_settings_only(self):
        rule = properties("dev.noctalia.Noctalia", "Noctalia Settings")
        self.assertEqual(rule["open-floating"], "true")
        self.assertEqual(rule["open-focused"], "true")
        for option in ("open-maximized", "open-maximized-to-edges", "open-fullscreen"):
            self.assertEqual(rule[option], "false")
        self.assertNotIn("open-on-workspace", rule)
        body = next(body for body in re.findall(r'^window-rule \{\n(.*?)^\}',
                    (CONFIG / "sub/rules/common.kdl").read_text(), re.MULTILINE | re.DOTALL)
                    if '^dev\\.noctalia\\.Noctalia$' in body)
        self.assertIn('default-column-width { proportion 0.52; }', body)
        self.assertIn('default-window-height { proportion 0.65; }', body)
        self.assertNotIn('default-floating-position', body)
        for app, title in [("dev.noctalia.Noctalia", "Launcher"),
                           ("dev.noctalia.Noctalia", "Noctalia Settings extra"),
                           ("other", "Noctalia Settings")]:
            self.assertNotIn("open-floating", properties(app, title))

    def test_editor_title_is_scoped(self):
        self.assertEqual(properties("kitty", "editor")["open-on-workspace"], '"code"')
        self.assertNotIn("open-on-workspace", properties("other", "editor"))
        self.assertEqual(properties("zen", "Online editor")["open-on-workspace"], '"browser"')
        self.assertNotIn("open-on-workspace", properties("kitty", "another editor"))
        self.assertNotIn("open-floating", properties("other", "file-manager"))

    def test_anki_dialogs_are_scoped_and_not_routed(self):
        self.assertEqual(properties("anki", "Anki")["open-on-workspace"], '"anki"')
        for title in ("Add", "Add Note", "Preferences", "Browse", "Добавить"):
            rule = properties("anki", title)
            self.assertEqual(rule["open-floating"], "true", title)
            self.assertNotIn("open-on-workspace", rule, title)
            self.assertNotIn("open-on-workspace", properties("other", title))
            self.assertNotIn("open-floating", properties("other", title))

    def test_existing_app_policies(self):
        for app, title, workspace in [
            ("org.telegram.desktop", "Telegram", "chats"),
            ("vesktop", "Discord | Friends", "chats"),
            ("zen", "Example page", "browser"),
            ("steam", "Steam", "gaming"),
            ("org.prismlauncher.PrismLauncher", "Prism Launcher 10.0.0", "gaming"),
            ("com.obsproject.Studio", "OBS 32", "gaming"),
            ("md.obsidian.Obsidian", "Example vault", "notes"),
        ]:
            with self.subTest(app=app, title=title):
                rule = properties(app, title)
                self.assertEqual(rule["open-on-workspace"], f'"{workspace}"')
                self.assertEqual(rule["open-maximized-to-edges"], "true")
        for app, title in [
            ("org.telegram.desktop", "Test contact"), ("vesktop", "Voice channel"),
            ("zen", "Picture-in-Picture"), ("steam", "Steam Settings"),
            ("org.prismlauncher.PrismLauncher", "Settings — Prism Launcher 10.0.0"),
            ("com.obsproject.Studio", "Settings"),
            ("md.obsidian.Obsidian", "Settings - Example vault"),
        ]:
            with self.subTest(app=app, title=title):
                rule = properties(app, title)
                self.assertEqual(rule["open-floating"], "true")
                self.assertNotIn("open-on-workspace", rule)
        self.assertEqual(properties("org.telegram.desktop", "Media viewer")["open-fullscreen"], "false")
        self.assertEqual(properties("Minecraft", "Example world")["open-fullscreen"], "true")
        self.assertNotIn("open-fullscreen", properties("com.obsproject.Studio", "Projector - Preview"))

    def test_code_workspace_layout_trial(self):
        for name, output in [("workspaces.kdl", "HDMI-A-1"),
                             ("workspaces-pc.kdl", "HDMI-A-1"),
                             ("workspaces-laptop.kdl", "eDP-1")]:
            source = (CONFIG / "sub" / name).read_text()
            code = re.search(r'workspace "code" \{\n(.*?)^\}', source, re.MULTILINE | re.DOTALL)[1]
            self.assertIn(f'open-on-output "{output}"', code)
            self.assertIn('default-column-display "normal"', code)
            self.assertIn('default-column-width { proportion 0.5; }', code)
            self.assertEqual(source.count('default-column-display'), 1)
        for app, title in [("kitty", "editor"), ("code", "Example project"),
                           ("dev.zed.Zed", "Example project")]:
            rule = properties(app, title)
            self.assertEqual(rule["open-on-workspace"], '"code"')
            self.assertEqual(rule["open-maximized"], "false")
            self.assertEqual(rule["open-maximized-to-edges"], "false")
        self.assertEqual(properties("kitty", "project-session")["open-maximized-to-edges"], "true")
        self.assertIn('default-column-display "tabbed"', (CONFIG / "sub/layout.kdl").read_text())

    def test_polkit_owned_by_systemd(self):
        self.assertNotIn("polkit", (CONFIG / "sub/startup.kdl").read_text())
        self.assertIn("systemd.user.services.polkit-gnome-authentication-agent-1",
                      (ROOT / "modules/desktop/niri/nixos.nix").read_text())


if __name__ == "__main__":
    unittest.main()
