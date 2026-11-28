import json
import subprocess
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

from greeter_wallpaper import current_output, publish


class GreeterWallpaperTest(unittest.TestCase):
    def test_output_pin_and_disconnected_fallback(self):
        dp = {"name": "DP-1", "connected": True}
        hdmi = {"name": "HDMI-A-1", "connected": True}
        with patch("subprocess.check_output") as current:
            current.return_value = json.dumps({"outputs": [dp, hdmi]})
            self.assertEqual(current_output("helm", "HDMI-A-1"), hdmi)
            hdmi["connected"] = False
            current.return_value = json.dumps({"outputs": [dp, hdmi]})
            self.assertEqual(current_output("helm", "HDMI-A-1"), dp)

    def test_failed_conversion_preserves_previous_image(self):
        with TemporaryDirectory() as directory:
            destination = Path(directory) / "background.jpg"
            destination.write_bytes(b"previous image")
            with patch("subprocess.run", side_effect=subprocess.CalledProcessError(1, "ffmpeg")):
                with self.assertRaises(subprocess.CalledProcessError):
                    publish("ffmpeg", Path("/wallpaper.mp4"), destination)
            self.assertEqual(destination.read_bytes(), b"previous image")
            self.assertEqual(list(destination.parent.iterdir()), [destination])
