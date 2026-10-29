"""Run only the read-only preflight against disposable home directories."""
import pathlib
import subprocess
import tempfile
import unittest

SCRIPT = pathlib.Path(__file__).resolve().parents[1] / "hosts/pc/check-home-layout.sh"


class HomeLayoutTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = pathlib.Path(self.temp.name)
        self.data = self.home / ".local/share"
        self.pictures = self.home / "pictures"
        self.data.mkdir(parents=True)
        self.pictures.mkdir()

    def check(self, success=True):
        # /proc is a real mount; this script never writes to the games path.
        result = subprocess.run(
            ["bash", str(SCRIPT), str(self.home), str(self.data), str(self.pictures), "/proc"],
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode == 0, success, result.stderr)
        return result

    def test_fresh_home_and_correct_links(self):
        self.check()
        for path, target in [("games", "/proc"), (".local/share/Steam/steamapps", "/proc/steam/steamapps"),
                             (".local/share/PrismLauncher/instances", "/proc/minecraft/instances")]:
            link = self.home / path
            link.parent.mkdir(parents=True, exist_ok=True)
            link.symlink_to(target)
        self.check()

    def test_unmounted_games_is_rejected(self):
        result = subprocess.run(["bash", str(SCRIPT), str(self.home), str(self.data),
                                 str(self.pictures), str(self.home)], capture_output=True)
        self.assertNotEqual(result.returncode, 0)

    def test_dev_symlink_is_preserved(self):
        path = self.home / "dev"
        path.symlink_to("/some/existing/projects")
        self.check(False)
        self.assertEqual(path.readlink(), pathlib.Path("/some/existing/projects"))

    def test_game_directories_and_files_are_preserved(self):
        for rel in ["games", ".local/share/Steam/steamapps", ".local/share/PrismLauncher/instances"]:
            with self.subTest(path=rel):
                path = self.home / rel
                path.mkdir(parents=True)
                marker = path / "keep"
                marker.write_text("existing data")
                self.check(False)
                self.assertEqual(marker.read_text(), "existing data")
                marker.unlink()
                path.rmdir()

    def test_legacy_steam_root_is_rejected(self):
        (self.home / ".steam").mkdir()
        (self.home / ".steam/steam").symlink_to("/old/steam")
        self.check(False)

    def test_custom_prism_path_is_rejected_without_editing_settings(self):
        cfg = self.data / "PrismLauncher/prismlauncher.cfg"
        cfg.parent.mkdir()
        for value, success in [("instances", True), ("/proc/minecraft/instances", True), ("/old/instances", False)]:
            cfg.write_text(f"[General]\nInstanceDir={value}\n")
            self.check(success)
            self.assertEqual(cfg.read_text(), f"[General]\nInstanceDir={value}\n")

    def test_wallpaper_files_are_preserved(self):
        path = self.pictures / "wallpapers"
        path.mkdir()
        marker = path / "keep.jpg"
        marker.write_bytes(b"existing wallpaper")
        self.check(False)
        self.assertEqual(marker.read_bytes(), b"existing wallpaper")


if __name__ == "__main__":
    unittest.main()
