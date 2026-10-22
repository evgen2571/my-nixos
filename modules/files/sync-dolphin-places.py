"""Merge declarative bookmarks into Dolphin's writable Places file."""

import json
import os
from pathlib import Path
import sys
import tempfile
from urllib.parse import urlsplit
import uuid
import xml.etree.ElementTree as ET


ICON = "{http://www.freedesktop.org/standards/desktop-bookmarks}icon"
OWNER = "my-nixos"
ET.register_namespace("bookmark", "http://www.freedesktop.org/standards/desktop-bookmarks")


def metadata(bookmark, owner):
    info = bookmark.find("info")
    if info is None:
        info = ET.SubElement(bookmark, "info")
    for item in info.findall("metadata"):
        if item.get("owner") == owner:
            return item
    return ET.SubElement(info, "metadata", owner=owner)


def set_text(parent, tag, value):
    child = parent.find(tag)
    if child is None:
        child = ET.SubElement(parent, tag)
    child.text = value


def sync(pins, target):
    wanted = {}
    for pin in pins:
        url = urlsplit(pin["url"])
        if (not url.scheme or url.password is not None or not pin["name"]
                or (url.scheme == "file" and not url.path.startswith("/"))):
            raise ValueError("Places require absolute URLs without passwords and nonempty labels")
        if pin["url"] in wanted:
            raise ValueError("Declarative Places URLs must be unique")
        wanted[pin["url"]] = pin
    if target.is_symlink():
        raise ValueError("Refusing to replace a symlinked Places file")
    original = target.read_bytes() if target.exists() else None
    parser = ET.XMLParser(target=ET.TreeBuilder(insert_comments=True))
    root = ET.fromstring(original, parser=parser) if original is not None else ET.Element("xbel", version="1.0")
    if root.tag != "xbel":
        raise ValueError("Expected an XBEL Places file")
    before = ET.tostring(root)
    selected = {}
    anchor = len(root)
    for index, bookmark in enumerate(list(root)):
        if bookmark.tag != "bookmark":
            continue
        managed = bookmark.find(f'./info/metadata[@owner="{OWNER}"]/managed') is not None
        url = bookmark.get("href")
        if url in wanted and bookmark.find("./info/metadata/UDI") is not None:
            raise ValueError("Device bookmarks must remain runtime-managed")
        if managed or (url in wanted and url not in selected):
            anchor = min(anchor, index)
            root.remove(bookmark)
            if url in wanted:
                selected.setdefault(url, bookmark)
    for offset, (url, pin) in enumerate(wanted.items()):
        bookmark = selected.get(url)
        if bookmark is None:
            bookmark = ET.Element("bookmark", href=url)
        set_text(bookmark, "title", pin["name"])
        kde = metadata(bookmark, "http://www.kde.org")
        if kde.find("ID") is None:
            set_text(kde, "ID", str(uuid.uuid5(uuid.NAMESPACE_URL, url)))
        icons = metadata(bookmark, "http://freedesktop.org")
        icon = icons.find(ICON)
        if icon is None:
            icon = ET.SubElement(icons, ICON)
        icon.set("name", pin["icon"])
        set_text(metadata(bookmark, OWNER), "managed", "true")
        root.insert(anchor + offset, bookmark)
    if ET.tostring(root) == before:
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    if original is not None:
        try:
            with target.with_name(target.name + ".before-my-nixos").open("xb") as backup:
                os.fchmod(backup.fileno(), 0o600)
                backup.write(original)
        except FileExistsError:
            pass
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=target.parent, delete=False) as output:
            temporary = Path(output.name)
            ET.ElementTree(root).write(output, encoding="utf-8", xml_declaration=True)
            output.flush()
            os.fsync(output.fileno())
        current = target.read_bytes() if target.exists() else None
        if target.is_symlink() or current != original:
            raise RuntimeError("Places changed during synchronization; close Dolphin and retry")
        os.replace(temporary, target)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    sync(json.loads(Path(sys.argv[1]).read_text()), Path(sys.argv[2]))
