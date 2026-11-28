import json
import subprocess
import sys
from pathlib import Path
from tempfile import TemporaryDirectory


def current_output(helm, connector):
    result = subprocess.check_output([helm, "current", "--json"], timeout=5)
    outputs = [output for output in json.loads(result)["outputs"] if output["connected"]]
    return next(
        (output for output in outputs if output["name"] == connector),
        next(iter(outputs), None),
    )


def publish(ffmpeg, source, destination):
    # Keep the previous image readable until the replacement is complete.
    with TemporaryDirectory(dir=destination.parent) as directory:
        image = Path(directory) / destination.name
        subprocess.run(
            [
                ffmpeg,
                "-nostdin", "-loglevel", "error",
                "-protocol_whitelist", "file", "-i", str(source),
                "-map", "0:v:0", "-frames:v", "1", "-q:v", "2", "-update", "1",
                str(image),
            ],
            check=True,
            timeout=30,
        )
        image.chmod(0o640)
        image.replace(destination)


def watch(helm, ffmpeg, connector, destination):
    last_image = None

    def sync(clear=False):
        nonlocal last_image
        output = current_output(helm, connector)
        if output is None:
            return
        if not output["path"]:
            if clear:
                destination.unlink(missing_ok=True)
                last_image = None
            return
        # shortcut: Wallpaper Engine scenes need a daemon-provided preview path.
        if output["type"] not in ("static", "video"):
            return
        source = Path(output["path"])
        try:
            if not source.is_absolute() or not source.is_file():
                raise ValueError(f"wallpaper is not a local file: {source}")
            image = (source, source.stat().st_mtime_ns)
            if image != last_image or not destination.exists():
                publish(ffmpeg, source, destination)
                last_image = image
        except (OSError, ValueError, subprocess.SubprocessError) as error:
            print(f"Could not publish Skwd wallpaper: {error}", file=sys.stderr)

    with subprocess.Popen([helm, "watch"], stdout=subprocess.PIPE, text=True) as events:
        try:
            sync()
            for line in events.stdout:
                event = json.loads(line)["event"]
                if event in ("skwd.wall.applied", "skwd.wall.cleared", "skwd.wall.outputs_changed"):
                    sync(clear=event == "skwd.wall.cleared")
        finally:
            events.terminate()


if __name__ == "__main__":
    helm, ffmpeg, connector, destination = sys.argv[1:]
    watch(helm, ffmpeg, connector, Path(destination))
