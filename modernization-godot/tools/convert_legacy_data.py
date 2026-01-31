#!/usr/bin/env python
import argparse
import base64
import json
import math
import re
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SERVER_DIR = ROOT / "Server"
MAPS_DIR = SERVER_DIR / "Maps"
CLIENT_DIR = ROOT / "Client"
OUT_DIR_DEFAULT = ROOT / "modernization-godot" / "data"


def read_text(path: Path) -> str:
    return path.read_text(encoding="latin-1", errors="replace")


def parse_ini(text: str) -> dict:
    sections = []
    current = None
    for raw_line in text.splitlines():
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
    return {"type": "ini", "sections": sections}


def parse_sectioned_list(ini: dict, prefix: str) -> dict:
    items = []
    init = None
    for section in ini["sections"]:
        name = section["name"]
        if name.upper() == "INIT":
            init = section["values"]
            continue
        if name.lower().startswith(prefix.lower()):
            suffix = name[len(prefix) :]
            try:
                item_id = int(suffix)
            except ValueError:
                item_id = None
            items.append({"id": item_id, "values": section["values"]})
    return {"type": "ini-list", "init": init, "items": items}


def infer_grid(size: int) -> tuple[int, int, int] | None:
    if size % 10000 == 0:
        return 100, 100, size // 10000
    preferred = [128, 100, 96, 80, 64, 120, 160, 200, 256]
    for dim in preferred:
        cells = dim * dim
        if size % cells == 0:
            return dim, dim, size // cells
    for dim in range(16, 512):
        cells = dim * dim
        if size % cells == 0:
            return dim, dim, size // cells
    return None


def encode_binary(path: Path) -> dict:
    data = path.read_bytes()
    grid = infer_grid(len(data))
    out = {
        "type": "binary",
        "size": len(data),
        "bytes_base64": base64.b64encode(data).decode("ascii"),
    }
    if grid is not None:
        out["grid"] = {
            "width": grid[0],
            "height": grid[1],
            "tile_stride_bytes": grid[2],
        }
    return out


def infer_map_dims(size: int, stride: int, default: tuple[int, int]) -> tuple[int, int]:
    tiles = size // stride if stride > 0 else 0
    default_tiles = default[0] * default[1]
    if tiles == default_tiles:
        return default
    root = int(math.isqrt(tiles))
    if root * root == tiles and root > 0:
        return root, root
    return default


def parse_map_layer(path: Path, default_dims: tuple[int, int], warnings: list[str]) -> dict:
    data = path.read_bytes()
    stride = 7
    width, height = infer_map_dims(len(data), stride, default_dims)
    expected = width * height * stride
    if expected != len(data):
        warnings.append(
            f"{path}: map layer size {len(data)} does not match {width}x{height}x{stride}."
        )

    blocked = []
    g1 = []
    g2 = []
    g3 = []

    offset = 0
    for _y in range(height):
        row_blocked = []
        row_g1 = []
        row_g2 = []
        row_g3 = []
        for _x in range(width):
            if offset + stride <= len(data):
                b, v1, v2, v3 = struct.unpack_from("<Bhhh", data, offset)
            else:
                b, v1, v2, v3 = 0, 0, 0, 0
            offset += stride
            row_blocked.append(int(b))
            row_g1.append(int(v1))
            row_g2.append(int(v2))
            row_g3.append(int(v3))
        blocked.append(row_blocked)
        g1.append(row_g1)
        g2.append(row_g2)
        g3.append(row_g3)

    return {
        "type": "map",
        "width": width,
        "height": height,
        "blocked": blocked,
        "graphics": [g1, g2, g3],
        "raw": {
            "size": len(data),
            "stride": stride,
        },
    }


def parse_inf_layer(path: Path, default_dims: tuple[int, int], warnings: list[str]) -> dict:
    data = path.read_bytes()
    tiles = default_dims[0] * default_dims[1]
    stride = len(data) // tiles if tiles > 0 else 0
    if stride <= 0:
        stride = 16
    if stride % 2 != 0:
        warnings.append(f"{path}: inf stride {stride} is not divisible by 2.")
    if stride not in (12, 16, 20):
        warnings.append(f"{path}: inf stride {stride} is unusual.")

    width, height = infer_map_dims(len(data), stride, default_dims)
    expected = width * height * stride
    if expected != len(data):
        warnings.append(
            f"{path}: inf layer size {len(data)} does not match {width}x{height}x{stride}."
        )
    fields_per_tile = stride // 2
    fmt = "<" + "h" * fields_per_tile

    tile_exit_map = []
    tile_exit_x = []
    tile_exit_y = []
    npc_index = []
    reserved = []

    offset = 0
    for _y in range(height):
        row_map = []
        row_x = []
        row_y = []
        row_npc = []
        row_res = []
        for _x in range(width):
            if offset + stride <= len(data):
                values = list(struct.unpack_from(fmt, data, offset))
            else:
                values = [0] * fields_per_tile
            offset += stride
            row_map.append(int(values[0]) if len(values) > 0 else 0)
            row_x.append(int(values[1]) if len(values) > 1 else 0)
            row_y.append(int(values[2]) if len(values) > 2 else 0)
            row_npc.append(int(values[3]) if len(values) > 3 else 0)
            row_res.append([int(v) for v in values[4:]])
        tile_exit_map.append(row_map)
        tile_exit_x.append(row_x)
        tile_exit_y.append(row_y)
        npc_index.append(row_npc)
        reserved.append(row_res)

    return {
        "type": "inf",
        "width": width,
        "height": height,
        "tile_exit_map": tile_exit_map,
        "tile_exit_x": tile_exit_x,
        "tile_exit_y": tile_exit_y,
        "npc_index": npc_index,
        "reserved": reserved,
        "raw": {
            "size": len(data),
            "stride": stride,
            "fields_per_tile": fields_per_tile,
        },
    }


def parse_obj_layer(path: Path, default_dims: tuple[int, int], warnings: list[str]) -> dict:
    data = path.read_bytes()
    stride = 14
    width, height = infer_map_dims(len(data), stride, default_dims)
    expected = width * height * stride
    if expected != len(data):
        warnings.append(
            f"{path}: obj layer size {len(data)} does not match {width}x{height}x{stride}."
        )

    obj_index = []
    amount = []
    locked = []
    sign = []
    sign_owner = []

    offset = 0
    for _y in range(height):
        row_obj = []
        row_amt = []
        row_lock = []
        row_sign = []
        row_owner = []
        for _x in range(width):
            if offset + stride <= len(data):
                v_obj, v_amt, v_lock, v_sign, v_owner = struct.unpack_from(
                    "<hhihi", data, offset
                )
            else:
                v_obj, v_amt, v_lock, v_sign, v_owner = 0, 0, 0, 0, 0
            offset += stride
            row_obj.append(int(v_obj))
            row_amt.append(int(v_amt))
            row_lock.append(int(v_lock))
            row_sign.append(int(v_sign))
            row_owner.append(int(v_owner))
        obj_index.append(row_obj)
        amount.append(row_amt)
        locked.append(row_lock)
        sign.append(row_sign)
        sign_owner.append(row_owner)

    return {
        "type": "obj",
        "width": width,
        "height": height,
        "obj_index": obj_index,
        "amount": amount,
        "locked": locked,
        "sign": sign,
        "sign_owner": sign_owner,
        "raw": {
            "size": len(data),
            "stride": stride,
        },
    }


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def convert_ini_files(out_dir: Path) -> None:
    ini_files = [
        (SERVER_DIR / "NPC.dat", "npc"),
        (SERVER_DIR / "NPC2.dat", "npc2"),
        (SERVER_DIR / "OBJ.dat", "objects"),
        (SERVER_DIR / "Spells.dat", "spells"),
        (SERVER_DIR / "quests.txt", "quests"),
        (SERVER_DIR / "signs.txt", "signs"),
        (SERVER_DIR / "clans.txt", "clans"),
        (SERVER_DIR / "gossip.txt", "gossip"),
        (SERVER_DIR / "Help.dat", "help"),
        (SERVER_DIR / "Msgboard.txt", "msgboard"),
        (SERVER_DIR / "Gmque.txt", "gm_queue"),
        (SERVER_DIR / "bugs.txt", "bugs"),
        (SERVER_DIR / "banned.txt", "banned"),
        (SERVER_DIR / "Server.ini", "server_config"),
        (MAPS_DIR / "Map.dat", "map_index"),
        (CLIENT_DIR / "Game.ini", "client_config"),
        (CLIENT_DIR / "Tips.txt", "tips"),
    ]
    for path, out_name in ini_files:
        if not path.exists():
            continue
        data = parse_ini(read_text(path))
        data["source"] = str(path.relative_to(ROOT))
        out_path = out_dir / "legacy-json" / f"{out_name}.json"
        write_json(out_path, data)


def parse_grh_dat(path: Path, warnings: list[str]) -> dict:
    data = path.read_bytes()
    if len(data) % 2 != 0:
        warnings.append(f"{path}: Grh.dat size {len(data)} is not even.")
    count = len(data) // 2
    values = struct.unpack_from("<" + "h" * count, data, 0)

    index = 0
    if count < 6:
        warnings.append(f"{path}: Grh.dat too small to parse.")
        return {"type": "grh", "entries": []}

    header = list(values[index : index + 5])
    index += 5

    entries = []
    if index >= count:
        warnings.append(f"{path}: Grh.dat missing first entry.")
        return {"type": "grh", "header": header, "entries": entries}

    while index < count:
        grh_id = values[index]
        index += 1
        if grh_id == 0:
            break
        if index >= count:
            warnings.append(f"{path}: Grh {grh_id} truncated before NumFrames.")
            break

        num_frames = values[index]
        index += 1

        if num_frames > 1:
            if index + num_frames > count:
                warnings.append(f"{path}: Grh {grh_id} frames truncated.")
                break
            frames = list(values[index : index + num_frames])
            index += num_frames
            if index >= count:
                warnings.append(f"{path}: Grh {grh_id} missing speed.")
                break
            speed = values[index]
            index += 1
            entry = {
                "id": int(grh_id),
                "num_frames": int(num_frames),
                "frames": [int(v) for v in frames],
                "speed": int(speed),
            }
        else:
            if index + 5 > count:
                warnings.append(f"{path}: Grh {grh_id} truncated in base data.")
                break
            file_num = values[index]
            sx = values[index + 1]
            sy = values[index + 2]
            pixel_w = values[index + 3]
            pixel_h = values[index + 4]
            index += 5
            entry = {
                "id": int(grh_id),
                "num_frames": int(num_frames),
                "file_num": int(file_num),
                "sx": int(sx),
                "sy": int(sy),
                "pixel_width": int(pixel_w),
                "pixel_height": int(pixel_h),
                "tile_width": float(pixel_w) / 32.0,
                "tile_height": float(pixel_h) / 32.0,
            }

        entries.append(entry)

    return {"type": "grh", "header": header, "entries": entries}


def convert_client_files(out_dir: Path, warnings: list[str]) -> None:
    ini_files = [
        ("Grh.ini", "grh"),
        ("Body.dat", "body"),
        ("Head.dat", "head"),
        ("wpanim.dat", "weapon_anim"),
        ("shanim.dat", "shield_anim"),
    ]
    for filename, out_name in ini_files:
        path = CLIENT_DIR / filename
        if not path.exists():
            continue
        ini = parse_ini(read_text(path))
        if filename.lower() in ("body.dat", "head.dat", "wpanim.dat", "shanim.dat"):
            prefix = {
                "body.dat": "Body",
                "head.dat": "Head",
                "wpanim.dat": "WeaponAnim",
                "shanim.dat": "ShieldAnim",
            }[filename.lower()]
            data = parse_sectioned_list(ini, prefix)
        else:
            data = ini
        data["source"] = str(path.relative_to(ROOT))
        out_path = out_dir / "client" / f"{out_name}.json"
        write_json(out_path, data)

    grh_dat = CLIENT_DIR / "Grh.dat"
    if grh_dat.exists():
        data = parse_grh_dat(grh_dat, warnings)
        data["source"] = str(grh_dat.relative_to(ROOT))
        out_path = out_dir / "client" / "grh_data.json"
        write_json(out_path, data)


def convert_text_files(out_dir: Path) -> None:
    text_files = [
        (SERVER_DIR / "Readme.txt", "server_readme"),
        (CLIENT_DIR / "Readme.txt", "client_readme"),
        (CLIENT_DIR / "Problems.txt", "client_problems"),
        (CLIENT_DIR / "News.txt", "client_news"),
        (CLIENT_DIR / "version.ver", "client_version"),
        (SERVER_DIR / "Clans" / "ClanInfo.txt", "clan_info"),
    ]
    for path, out_name in text_files:
        if not path.exists():
            continue
        text = read_text(path)
        payload = {
            "type": "text",
            "source": str(path.relative_to(ROOT)),
            "text": text,
            "lines": text.splitlines(),
        }
        out_path = out_dir / "text" / f"{out_name}.json"
        write_json(out_path, payload)


def convert_maps(out_dir: Path, warnings: list[str]) -> None:
    map_dat_files = sorted(MAPS_DIR.glob("Map*.dat"))
    map_re = re.compile(r"Map(\d+)\.dat", re.IGNORECASE)

    for dat_path in map_dat_files:
        match = map_re.match(dat_path.name)
        if not match:
            continue
        map_id = int(match.group(1))

        meta = parse_ini(read_text(dat_path))
        default_dims = (100, 100)
        entry = {
            "id": map_id,
            "meta": meta,
            "source": {
                "dat": str(dat_path.relative_to(ROOT)),
            },
            "layers": {},
        }

        for suffix in ["map", "obj", "inf"]:
            bin_path = dat_path.with_suffix(f".{suffix}")
            if bin_path.exists():
                if suffix == "map":
                    entry["layers"][suffix] = parse_map_layer(
                        bin_path, default_dims, warnings
                    )
                elif suffix == "inf":
                    entry["layers"][suffix] = parse_inf_layer(
                        bin_path, default_dims, warnings
                    )
                elif suffix == "obj":
                    entry["layers"][suffix] = parse_obj_layer(
                        bin_path, default_dims, warnings
                    )
                else:
                    entry["layers"][suffix] = encode_binary(bin_path)
                entry["source"][suffix] = str(bin_path.relative_to(ROOT))

        out_path = out_dir / "maps" / f"Map{map_id}.json"
        write_json(out_path, entry)


def load_num_maps() -> int | None:
    map_dat = MAPS_DIR / "Map.dat"
    if not map_dat.exists():
        return None
    ini = parse_ini(read_text(map_dat))
    for section in ini["sections"]:
        if section["name"].upper() == "INIT":
            value = section["values"].get("NumMaps")
            if value is not None:
                try:
                    return int(value)
                except ValueError:
                    return None
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description="Convert legacy VB6 data into JSON.")
    parser.add_argument(
        "--out",
        default=str(OUT_DIR_DEFAULT),
        help="Output directory for JSON files.",
    )
    parser.add_argument(
        "--maps",
        action="store_true",
        help="Convert map data (Map*.dat + .map/.obj/.inf).",
    )
    parser.add_argument(
        "--ini",
        action="store_true",
        help="Convert INI-style data files (NPC, OBJ, Spells, etc).",
    )
    parser.add_argument(
        "--client",
        action="store_true",
        help="Convert client graphics data (Grh/Body/Head/Weapon/Shield).",
    )
    parser.add_argument(
        "--text",
        action="store_true",
        help="Convert plain text files (readmes, notes, version).",
    )
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Print warnings for map layer size or stride anomalies.",
    )
    args = parser.parse_args()

    out_dir = Path(args.out)
    if not args.maps and not args.ini:
        args.maps = True
        args.ini = True
        args.client = True
        args.text = True

    warnings: list[str] = []

    if args.maps and args.validate:
        declared = load_num_maps()
        if declared is not None:
            actual = len(list(MAPS_DIR.glob("Map*.dat")))
            if actual < declared:
                warnings.append(
                    f"{MAPS_DIR}: Map.dat declares {declared} maps but only {actual} Map*.dat files exist."
                )

    if args.ini:
        convert_ini_files(out_dir)
    if args.maps:
        convert_maps(out_dir, warnings)
    if args.client:
        convert_client_files(out_dir, warnings)
    if args.text:
        convert_text_files(out_dir)

    if args.validate and warnings:
        print("Warnings:")
        for warning in warnings:
            print(f"- {warning}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
