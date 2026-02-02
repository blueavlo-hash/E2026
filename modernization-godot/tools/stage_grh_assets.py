#!/usr/bin/env python
import argparse
import json
import re
import shutil
import subprocess
import struct
import zlib
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
        "--convert",
        action="store_true",
        help="Convert BMP files to PNG in dest using ffmpeg.",
    )
    parser.add_argument(
        "--report",
        default=str(ROOT / "modernization-godot" / "data" / "client" / "grh_files.json"),
        help="Write a JSON report of available/missing GRH files.",
    )
    parser.add_argument(
        "--include-masks",
        action="store_true",
        help="Also stage mask files (grh###M.bmp) when present.",
    )
    args = parser.parse_args()

    source = Path(args.source)
    dest = Path(args.dest)
    report_path = Path(args.report)
    ffmpeg_path = shutil.which("ffmpeg")

    if not source.exists():
        raise SystemExit(f"Source folder not found: {source}")

    pattern = re.compile(r"(grh|ghr|gh)(\d+)(m?)\.bmp$", re.IGNORECASE)
    files = list(source.glob("*.bmp"))

    mapping = {}
    masks = {}
    extras = []
    for path in files:
        match = pattern.match(path.name)
        if not match:
            extras.append(path.name)
            continue
        grh_id = int(match.group(2))
        is_mask = match.group(3).lower() == "m"
        if is_mask:
            masks[grh_id] = path
        else:
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

    if args.copy or args.convert:
        dest.mkdir(parents=True, exist_ok=True)
        failed = []
        for grh_id, src in mapping.items():
            if args.convert:
                target = dest / f"Grh{grh_id}.png"
                converted = False
                if ffmpeg_path is not None:
                    cmd = [ffmpeg_path, "-y", "-i", str(src), str(target)]
                    result = subprocess.run(cmd, capture_output=True)
                    converted = result.returncode == 0
                if not converted:
                    if not convert_bmp_to_png(src, target):
                        failed.append(src.name)
            else:
                target = dest / f"Grh{grh_id}.bmp"
                if not target.exists():
                    shutil.copy2(src, target)
        if args.include_masks:
            for grh_id, src in masks.items():
                if args.convert:
                    target = dest / f"Grh{grh_id}M.png"
                    converted = False
                    if ffmpeg_path is not None:
                        cmd = [ffmpeg_path, "-y", "-i", str(src), str(target)]
                        result = subprocess.run(cmd, capture_output=True)
                        converted = result.returncode == 0
                    if not converted:
                        if not convert_bmp_to_png(src, target):
                            failed.append(src.name)
                else:
                    target = dest / f"Grh{grh_id}M.bmp"
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
        "mask_count": len(masks),
        "mask_ids": sorted(masks.keys()),
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
    if args.convert:
        print(f"Converted to PNG in: {dest}")
    if args.include_masks:
        print(f"Masks staged: {len(masks)}")
    if args.convert and ffmpeg_path is None:
        print("ffmpeg not found; used Python conversion for supported RLE4 BMPs.")
    if failed:
        print(f"Skipped: {len(failed)} BMP(s) could not be converted.")
    print(f"Report: {report_path}")
    if extras:
        print(f"Extras (non-standard names): {len(extras)}")
    return 0


def convert_bmp_to_png(source: Path, target: Path) -> bool:
    info = read_bmp_info(source)
    if info is None:
        return False
    width, height, bpp, compression, palette = info
    if bpp == 4 and compression == 2 and palette:
        indices = decode_rle4_bmp(source, width, height)
        if indices is None:
            return False
        rgba = indices_to_rgba(indices, width, height, palette)
        write_png_rgba(target, width, height, rgba)
        return True
    return False


def read_bmp_info(path: Path):
    data = path.read_bytes()
    if len(data) < 54 or data[0:2] != b"BM":
        return None
    header = data[0:14]
    dib_size = struct.unpack_from("<I", data, 14)[0]
    if dib_size < 40:
        return None
    width, height, planes, bpp = struct.unpack_from("<iiHH", data, 18)
    compression = struct.unpack_from("<I", data, 30)[0]
    colors_used = struct.unpack_from("<I", data, 46)[0]
    if width <= 0 or height == 0 or planes != 1:
        return None
    height = abs(height)
    palette = []
    if bpp <= 8:
        count = colors_used if colors_used else (1 << bpp)
        palette_offset = 14 + dib_size
        entry_size = 4
        for i in range(count):
            base = palette_offset + i * entry_size
            if base + 4 > len(data):
                break
            b, g, r, _ = struct.unpack_from("<BBBB", data, base)
            palette.append((r, g, b))
    return width, height, bpp, compression, palette


def decode_rle4_bmp(path: Path, width: int, height: int):
    data = path.read_bytes()
    offset = struct.unpack_from("<I", data, 10)[0]
    if offset >= len(data):
        return None
    stream = data[offset:]
    indices = bytearray(width * height)

    x = 0
    y = height - 1
    i = 0
    while i + 1 < len(stream) and y >= 0:
        count = stream[i]
        value = stream[i + 1]
        i += 2
        if count > 0:
            for n in range(count):
                if x >= width:
                    break
                index = (value >> 4) if (n % 2 == 0) else (value & 0x0F)
                set_index(indices, width, x, y, index)
                x += 1
        else:
            if value == 0:
                x = 0
                y -= 1
            elif value == 1:
                break
            elif value == 2:
                if i + 1 >= len(stream):
                    break
                dx = stream[i]
                dy = stream[i + 1]
                i += 2
                x += dx
                y -= dy
            else:
                count_abs = value
                bytes_count = (count_abs + 1) // 2
                for n in range(count_abs):
                    if i + (n // 2) >= len(stream) or x >= width:
                        break
                    byte = stream[i + (n // 2)]
                    index = (byte >> 4) if (n % 2 == 0) else (byte & 0x0F)
                    set_index(indices, width, x, y, index)
                    x += 1
                i += bytes_count
                if bytes_count % 2 == 1:
                    i += 1
    return indices


def set_index(indices: bytearray, width: int, x: int, y: int, index: int) -> None:
    pos = y * width + x
    indices[pos] = index


def indices_to_rgba(indices: bytearray, width: int, height: int, palette: list[tuple[int, int, int]]) -> bytearray:
    rgba = bytearray(width * height * 4)
    if not indices:
        return rgba
    key_index = 0
    for y in range(height):
        for x in range(width):
            index = indices[y * width + x]
            if index < len(palette):
                r, g, b = palette[index]
            else:
                r, g, b = (0, 0, 0)
            pos = (y * width + x) * 4
            rgba[pos] = r
            rgba[pos + 1] = g
            rgba[pos + 2] = b
            rgba[pos + 3] = 0 if index == key_index else 255
    return rgba


def write_png_rgba(path: Path, width: int, height: int, rgba: bytearray) -> None:
    def chunk(tag: bytes, payload: bytes) -> bytes:
        return struct.pack(">I", len(payload)) + tag + payload + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF)

    raw = bytearray()
    stride = width * 4
    for y in range(height):
        raw.append(0)
        row = rgba[y * stride : (y + 1) * stride]
        raw.extend(row)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    data = zlib.compress(bytes(raw), level=6)
    png = b"".join(
        [
            b"\x89PNG\r\n\x1a\n",
            chunk(b"IHDR", ihdr),
            chunk(b"IDAT", data),
            chunk(b"IEND", b""),
        ]
    )
    path.write_bytes(png)


if __name__ == "__main__":
    raise SystemExit(main())
