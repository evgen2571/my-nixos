"""Exercise KDE's file-opening path with isolated apps, config, cache and D-Bus."""

import argparse
import os
from pathlib import Path
import subprocess
import sys
import tempfile


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--menu", type=Path)
parser.add_argument("--mimeapps", type=Path, required=True)
parser.add_argument("--mime-data", type=Path, required=True)
args = parser.parse_args()

with tempfile.TemporaryDirectory(prefix="dolphin-open-files-") as directory:
    root = Path(directory)
    config = root / "config"
    applications = root / "data/applications"
    config.mkdir()
    applications.mkdir(parents=True)
    (config / "mimeapps.list").write_text(args.mimeapps.read_text())
    if args.menu:
        (config / "menus").mkdir()
        (config / "menus/applications.menu").write_text(args.menu.read_text())

    helper = root / "open.py"
    marker = root / "opened"
    helper.write_text("from pathlib import Path\nimport sys\n"
                      f"Path({str(marker)!r}).write_text(sys.argv[1])\n")
    for app, types in [("mpv", "audio/mpeg;video/mp4;"),
                       ("qimgv", "image/png;image/jpeg;")]:
        (applications / f"{app}.desktop").write_text(
            f"[Desktop Entry]\nType=Application\nName={app}\n"
            f"Exec={sys.executable} {helper} {app} %U\nMimeType={types}\n")

    env = dict(os.environ, HOME=str(root), XDG_CONFIG_HOME=str(config),
               XDG_CONFIG_DIRS=str(config), XDG_CACHE_HOME=str(root / "cache"),
               XDG_DATA_HOME=str(root / "data"), XDG_DATA_DIRS=str(args.mime_data),
               XDG_CURRENT_DESKTOP="niri", QT_QPA_PLATFORM="offscreen")
    subprocess.run(["kbuildsycoca6", "--noincremental"], env=env, check=True,
                   capture_output=True, text=True, timeout=20)
    for extension, mime, app in [("mp3", "audio/mpeg", "mpv"),
                                  ("mp4", "video/mp4", "mpv"),
                                  ("png", "image/png", "qimgv"),
                                  ("jpg", "image/jpeg", "qimgv")]:
        fixture = root / f"example.{extension}"
        fixture.touch()
        marker.unlink(missing_ok=True)
        result = subprocess.run(["kioclient", "exec", str(fixture), mime],
                                env=env, capture_output=True, text=True, timeout=10)
        assert result.returncode == 0, f"KIO failed to open {mime}: {result.stderr}"
        assert marker.read_text() == app, f"KIO did not launch {app} for {mime}"
        print(f"PASS: KIO opens {mime} with {app}", flush=True)
