#!/usr/bin/env python
import argparse
import json
import re
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SOURCE = ROOT / "GameData" / "Grh"
DEFAULT_DEST = ROOT / "modernization-godot" / "client-godot" / "assets" / "grh"
GRH_INI = ROOT / "Client" / "Grh.ini"
GRH_DATA_JSON = ROOT / "modernization-godot" / "data" / "client" / "grh_data.json"


def parse_ini(path: Path) -> dict:
    sections = []
    current = None
    for raw_line in path.read_text(encoding="latin-1", errors="replace").splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith("'") or line.startswith(";"):
            continue
        if line.startswith("[") and line.endswith("]"):
            if current is not None:
                sections.append(current)
            current = {"name": line[1:-1], "values": {}}
            continue
        if "=" in line and current is not None:
            key, value = line.split("=", 1)
            current["values"][key.strip()] = value.strip()
    if current is not None:
        sections.append(current)
    return {"sections": sections}


def get_num_grh_files() -> int | None:
    if not GRH_INI.exists():
        return None
    ini = parse_ini(GRH_INI)
    for section in ini["sections"]:
        if section["name"].upper() == "INIT":
            value = section["values"].get("NumGrhFiles")
            if value is not None:
                try:
                    return int(value)
                except ValueError:
                    return None
    return None


def get_grh_data_file_nums() -> set[int]:
    if not GRH_DATA_JSON.exists():
        return set()
    try:
        data = json.loads(GRH_DATA_JSON.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return set()
    file_nums = set()
    for entry in data.get("entries", []):
        value = entry.get("file_num")
        if isinstance(value, int):
            file_nums.add(value)
    return file_nums


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Stage GRH sprite sheets into the Godot project."
    )
    parser.add_argument("--source", default=str(DEFAULT_SOURCE))
    parser.add_argument("--dest", default=str(DEFAULT_DEST))
    parser.add_argument("--copy", action="store_true", help="Copy files into dest.")
    parser.add_argument(
        "--report",
        default=str(ROOT / "modernization-godot" / "data" / "client" / "grh_files.json"),
        help="Write a JSON report of available/missing GRH files.",
    )
    args = parser.parse_args()

    source = Path(args.source)
    dest = Path(args.dest)
    report_path = Path(args.report)

    if not source.exists():
        raise SystemExit(f"Source folder not found: {source}")

    pattern = re.compile(r"(grh|ghr|gh)(\d+)\.bmp$", re.IGNORECASE)
    files = list(source.glob("*.bmp"))

    mapping = {}
    extras = []
    for path in files:
        match = pattern.match(path.name)
        if not match:
            extras.append(path.name)
            continue
        grh_id = int(match.group(2))
        mapping[grh_id] = path

    num_grh = get_num_grh_files()
    grh_data_files = get_grh_data_file_nums()
    missing = []
    available = sorted(mapping.keys())
    if grh_data_files:
        for i in sorted(grh_data_files):
            if i not in mapping:
                missing.append(i)
    elif num_grh is not None:
        for i in range(1, num_grh + 1):
            if i not in mapping:
                missing.append(i)

    if args.copy:
        dest.mkdir(parents=True, exist_ok=True)
        for grh_id, src in mapping.items():
            target = dest / f"Grh{grh_id}.bmp"
            if not target.exists():
                shutil.copy2(src, target)

    report = {
        "source": str(source),
        "dest": str(dest),
        "num_grh_files": num_grh,
        "grh_data_file_nums": sorted(grh_data_files),
        "available_count": len(available),
        "missing_count": len(missing),
        "available": available,
        "missing": missing,
        "extras": extras,
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")

    print(f"GRH files found: {len(available)}")
    if num_grh is not None:
        print(f"Expected (from Grh.ini): {num_grh}")
    if grh_data_files:
        print(f"Referenced in Grh.dat: {len(grh_data_files)}")
    print(f"Missing: {len(missing)}")
    if args.copy:
        print(f"Copied to: {dest}")
    print(f"Report: {report_path}")
    if extras:
        print(f"Extras (non-standard names): {len(extras)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
