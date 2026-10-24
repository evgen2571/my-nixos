#!/usr/bin/env python3
"""Remove obsolete Noctalia GUI overrides, keeping a backup."""

import pathlib
import re
import shutil
import sys
import tomllib


path = pathlib.Path(sys.argv[1])
if not path.is_file():
    sys.exit(0)
original = path.read_text()
settings = tomllib.loads(original)
obsolete_widgets = {
    widget_id
    for widget_id, widget in settings.get("desktop_widgets", {}).get("widget", {}).items()
    if widget.get("type") == "noctalia/timer:desktop"
}
backup = path.with_suffix(".toml.before-noctalia-timer-cleanup")
if backup.exists():
    sys.exit(0)

lines = original.splitlines(keepends=True)
result = []
skip = False
heading = ""

for line in lines:
    if line.lstrip().startswith("["):
        heading = line.strip()
        widget_heading = re.match(
            r'^\[+desktop_widgets\.widget\.(?:"([^"]+)"|([^.\]]+))', heading
        )

        skip = bool(
            re.match(r"^\[+plugin_settings\.", heading)
            and "noctalia/screen_recorder" in heading
            or widget_heading
            and (widget_heading[1] or widget_heading[2]) in obsolete_widgets
        )

    if skip or re.match(r"^\s*launcher_session_search\s*=", line):
        continue
    if heading == "[desktop_widgets]":
        for widget_id in obsolete_widgets:
            line = re.sub(rf'''(['"]){re.escape(widget_id)}\1\s*,?''', "", line)
    result.append(line)

updated = "".join(result)
if updated == original:
    sys.exit(0)
tomllib.loads(updated)
shutil.copy2(path, backup)
path.write_text(updated)
