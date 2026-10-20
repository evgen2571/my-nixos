#!/usr/bin/env python3
"""Remove obsolete Noctalia GUI overrides from the v4-to-v5 transition."""

import pathlib
import re
import shutil
import sys
import tomllib


path = pathlib.Path(sys.argv[1])
if not path.is_file():
    sys.exit(0)
backup = path.with_suffix(".toml.before-noctalia-v5-cleanup")
if backup.exists():
    sys.exit(0)

original = path.read_text()
lines = original.splitlines(keepends=True)
result = []
skip = False

for line in lines:
    if line.lstrip().startswith("["):
        heading = line.strip()

        skip = bool(
            re.match(r"^\[+plugin_settings\.", heading)
            and "noctalia/screen_recorder" in heading
            or re.match(r"^\[+desktop_widgets\.widget\.", heading)
            and "desktop-widget-0000000000000003" in heading
        )

    if skip or re.match(r"^\s*launcher_session_search\s*=", line):
        continue
    result.append(line)

updated = "".join(result)
if updated == original:
    sys.exit(0)
tomllib.loads(updated)
shutil.copy2(path, backup)
path.write_text(updated)
