"""Validate disposable complete profile trees, rendering only Niri theme templates."""

import argparse
import json
import re
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
source = parser.add_mutually_exclusive_group(required=True)
source.add_argument("--generated-dir", type=Path, help="Existing Noctalia-generated Niri directory")
source.add_argument("--noctalia-template", type=Path, help="Packaged Noctalia assets/templates/niri/niri.kdl")
args = parser.parse_args()

with tempfile.TemporaryDirectory(prefix="niri-config-") as directory:
    temporary = Path(directory)
    for profile in ("default", "pc", "laptop"):
        target = temporary / profile
        shutil.copytree(ROOT / "config/niri", target)
        # Nix-store copies retain read-only modes; only the disposable tree is writable.
        for path in (target, *target.rglob("*")):
            path.chmod(path.stat().st_mode | stat.S_IWUSR)
        if profile != "default":
            shutil.copyfile(target / f"sub/workspaces-{profile}.kdl", target / "sub/workspaces.kdl")
        if args.generated_dir:
            shutil.copyfile(args.generated_dir / "noctalia.kdl", target / "noctalia.kdl")
        templates = {
            "layout": (ROOT / "config/noctalia/templates/niri-layout.kdl", target / "noctalia-layout.kdl"),
            "dropdown": (ROOT / "config/noctalia/templates/niri-dropdown.kdl", target / "noctalia-dropdown.kdl"),
        }
        if args.noctalia_template:
            templates["builtin"] = (args.noctalia_template.resolve(), target / "noctalia.kdl")
        config = temporary / "matugen.toml"
        config.write_text("[config]\n" + "".join(
            f"[templates.{name}]\ninput_path = {json.dumps(str(template))}\n"
            f"output_path = {json.dumps(str(output))}\n"
            for name, (template, output) in templates.items()
        ))
        for mode in ("dark", "light"):
            subprocess.run(["matugen", "color", "hex", "#85cfff", "--mode", mode,
                            "--config", str(config), "--quiet"], check=True)
            subprocess.run(["niri", "validate", "--config", str(target / "config.kdl")], check=True)
            assert "{{" not in (target / "noctalia-layout.kdl").read_text()
            assert re.search(
                r'color "#[0-9a-fA-F]{6}73"', (target / "noctalia-dropdown.kdl").read_text()
            )
            print(f"PASS: {profile} ({mode}, complete generated includes)", flush=True)
        for name in ("noctalia-layout.kdl", "noctalia-dropdown.kdl"):
            (target / name).unlink()
        subprocess.run(["niri", "validate", "--config", str(target / "config.kdl")], check=True)
        print(f"PASS: {profile} (optional theme files absent)", flush=True)
