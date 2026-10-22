"""Check managed Places without touching the user's bookmarks."""

import importlib.util
from pathlib import Path
import tempfile
import sys
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[2]
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("places", ROOT / "modules/files/sync-dolphin-places.py")
places = importlib.util.module_from_spec(spec)
spec.loader.exec_module(places)

FIXTURE = b'''<xbel><bookmark href="file:///home/example">
<title>Home</title><info><metadata owner="http://www.kde.org"><isSystemItem>true</isSystemItem></metadata></info>
</bookmark><bookmark href="file:///pictures"><title>Old name</title><info>
<metadata owner="http://www.kde.org"><ID>existing-id</ID><custom>keep</custom></metadata>
</info></bookmark><bookmark href="file:///device"><title>Device</title><info>
<metadata owner="http://www.kde.org"><UDI>device-id</UDI></metadata></info></bookmark>
<bookmark href="file:///manual"><title>Manual</title></bookmark></xbel>'''


class Places(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.target = Path(self.directory.name) / "user-places.xbel"
        self.target.write_bytes(FIXTURE)
        self.pins = [
            {"url": "file:///pictures", "name": "Pictures & art", "icon": "folder-pictures"},
            {"url": "sftp://example.invalid/files", "name": "Remote", "icon": "folder-remote"},
        ]

    def test_adoption_order_metadata_backup_and_idempotence(self):
        places.sync(self.pins, self.target)
        root = ET.parse(self.target).getroot()
        bookmarks = {b.get("href"): b for b in root.findall("bookmark")}
        self.assertEqual(list(bookmarks), ["file:///home/example", "file:///pictures",
                                         "sftp://example.invalid/files", "file:///device", "file:///manual"])
        picture = bookmarks["file:///pictures"]
        self.assertEqual(picture.findtext("title"), "Pictures & art")
        self.assertEqual(picture.findtext("./info/metadata/ID"), "existing-id")
        self.assertEqual(picture.findtext("./info/metadata/custom"), "keep")
        self.assertEqual(picture.find("./info/metadata/{http://www.freedesktop.org/standards/desktop-bookmarks}icon").get("name"), "folder-pictures")
        self.assertEqual(bookmarks["file:///device"].findtext("./info/metadata/UDI"), "device-id")
        backup = self.target.with_name("user-places.xbel.before-my-nixos")
        self.assertEqual(backup.read_bytes(), FIXTURE)
        content = self.target.read_bytes()
        places.sync(self.pins, self.target)
        self.assertEqual(self.target.read_bytes(), content)
        self.assertEqual(backup.read_bytes(), FIXTURE)

    def test_reorder_and_remove_only_managed_pins(self):
        places.sync(self.pins, self.target)
        places.sync(list(reversed(self.pins)), self.target)
        urls = [b.get("href") for b in ET.parse(self.target).getroot().findall("bookmark")]
        self.assertLess(urls.index(self.pins[1]["url"]), urls.index(self.pins[0]["url"]))
        places.sync([], self.target)
        self.assertEqual([b.get("href") for b in ET.parse(self.target).getroot().findall("bookmark")],
                         ["file:///home/example", "file:///device", "file:///manual"])

    def test_new_file_is_writable(self):
        self.target.unlink()
        places.sync(self.pins, self.target)
        self.assertTrue(self.target.stat().st_mode & 0o200)
        self.assertFalse(self.target.is_symlink())
        self.assertEqual(len(ET.parse(self.target).getroot().findall("bookmark")), 2)

    def test_invalid_input_and_xml_leave_original_unchanged(self):
        for pins in (self.pins * 2, [{"url": "relative", "name": "Bad", "icon": "folder"}],
                     [{"url": "file:relative", "name": "Bad", "icon": "folder"}],
                     [{"url": "file:///device", "name": "Device", "icon": "drive-harddisk"}],
                     [{"url": "sftp://user:example@example.invalid/files", "name": "Bad", "icon": "folder"}]):
            with self.assertRaises(ValueError):
                places.sync(pins, self.target)
            self.assertEqual(self.target.read_bytes(), FIXTURE)
        for content in (b"<broken", b"<other/>"):
            self.target.write_bytes(content)
            with self.assertRaises((ET.ParseError, ValueError)):
                places.sync(self.pins, self.target)
            self.assertEqual(self.target.read_bytes(), content)

    def test_symlink_and_failed_write_preserve_original(self):
        link = self.target.with_name("link.xbel")
        link.symlink_to(self.target)
        with self.assertRaises(ValueError):
            places.sync(self.pins, link)
        with patch.object(places.os, "replace", side_effect=OSError("write failed")):
            with self.assertRaises(OSError):
                places.sync(self.pins, self.target)
        self.assertEqual(self.target.read_bytes(), FIXTURE)

    def test_concurrent_change_is_not_overwritten(self):
        changed = b"<xbel><bookmark href='file:///new'/></xbel>"
        original_fsync = places.os.fsync

        def concurrent_write(fd):
            original_fsync(fd)
            self.target.write_bytes(changed)

        with patch.object(places.os, "fsync", side_effect=concurrent_write):
            with self.assertRaises(RuntimeError):
                places.sync(self.pins, self.target)
        self.assertEqual(self.target.read_bytes(), changed)


if __name__ == "__main__":
    unittest.main()
