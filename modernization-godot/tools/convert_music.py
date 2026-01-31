#!/usr/bin/env python
import argparse
import json
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SOURCE = ROOT / "GameData" / "Music"
DEFAULT_DEST = ROOT / "modernization-godot" / "client-godot" / "assets" / "music"
DEFAULT_REPORT = ROOT / "modernization-godot" / "data" / "client" / "music_convert.json"


def ffmpeg_available() -> bool:
    return shutil.which("ffmpeg") is not None


def convert_file(src: Path, dest: Path) -> dict:
    dest.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        "ffmpeg",
        "-y",
        "-i",
        str(src),
        "-acodec",
        "libvorbis",
        "-q:a",
        "4",
        str(dest),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return {
        "source": str(src),
        "dest": str(dest),
        "returncode": result.returncode,
        "stderr": result.stderr.strip(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Convert legacy MIDI files to OGG.")
    parser.add_argument("--source", default=str(DEFAULT_SOURCE))
    parser.add_argument("--dest", default=str(DEFAULT_DEST))
    parser.add_argument("--report", default=str(DEFAULT_REPORT))
    args = parser.parse_args()

    if not ffmpeg_available():
        raise SystemExit("ffmpeg not found in PATH.")

    source = Path(args.source)
    dest = Path(args.dest)
    report_path = Path(args.report)

    if not source.exists():
        raise SystemExit(f"Source folder not found: {source}")

    files = sorted(list(source.glob("*.mid")) + list(source.glob("*.midi")))
    results = []
    for src in files:
        out_name = src.stem + ".ogg"
        out_path = dest / out_name
        results.append(convert_file(src, out_path))

    report = {
        "source": str(source),
        "dest": str(dest),
        "converted": len(results),
        "results": results,
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")

    success = len([r for r in results if r["returncode"] == 0])
    print(f"Converted: {success}/{len(results)}")
    print(f"Report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
