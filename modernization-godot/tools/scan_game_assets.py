#!/usr/bin/env python
import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_GAMEDATA = ROOT / "GameData"
DEFAULT_REPORT = ROOT / "modernization-godot" / "data" / "assets_manifest.json"


def list_files(folder: Path, patterns: list[str]) -> list[dict]:
    items = []
    for pattern in patterns:
        for path in sorted(folder.glob(pattern)):
            items.append(
                {
                    "path": str(path.relative_to(ROOT)),
                    "size": path.stat().st_size,
                }
            )
    return items


def main() -> int:
    parser = argparse.ArgumentParser(description="Scan GameData assets into a JSON manifest.")
    parser.add_argument("--gamedata", default=str(DEFAULT_GAMEDATA))
    parser.add_argument("--report", default=str(DEFAULT_REPORT))
    args = parser.parse_args()

    gamedata = Path(args.gamedata)
    report_path = Path(args.report)
    if not gamedata.exists():
        raise SystemExit(f"GameData folder not found: {gamedata}")

    manifest = {"root": str(gamedata), "assets": {}}

    manifest["assets"]["grh"] = list_files(gamedata / "Grh", ["*.bmp", "*.jpg", "*.jpeg", "*.png"])
    manifest["assets"]["intro"] = list_files(gamedata / "Intro", ["*.jpg", "*.jpeg", "*.png"])
    manifest["assets"]["music"] = list_files(gamedata / "Music", ["*.mid", "*.midi", "*.mp3", "*.wav", "*.ogg"])
    manifest["assets"]["sound"] = list_files(gamedata / "Sound", ["*.wav", "*.mp3", "*.ogg"])
    manifest["assets"]["maps"] = list_files(gamedata / "Maps", ["*.map", "*.inf", "*.obj", "*.dat"])

    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    print(f"Report: {report_path}")
    for key, items in manifest["assets"].items():
        print(f"{key}: {len(items)} files")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
