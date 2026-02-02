from __future__ import annotations

import math
import struct
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from PySide6 import QtCore, QtGui, QtWidgets


ROOT = Path(__file__).resolve().parents[1]
MAPS_DIR = ROOT / "Server" / "Maps"
GRH_DIRS = [ROOT / "GameData" / "Grh", ROOT / "Client" / "Grh", ROOT / "MapEditorSource"]
GRH_DAT = ROOT / "Client" / "Grh.dat"

TILE_SIZE = 50


@dataclass
class GrhEntry:
    id: int
    num_frames: int
    frames: List[int]
    speed: int
    file_num: int
    sx: int
    sy: int
    w: int
    h: int
    tile_w: float
    tile_h: float


class GrhDatabase:
    def __init__(self, dat_path: Path) -> None:
        self.entries: Dict[int, GrhEntry] = {}
        if dat_path.exists():
            self._load(dat_path)

    def _load(self, path: Path) -> None:
        data = path.read_bytes()
        if len(data) < 12:
            return
        count = len(data) // 2
        values = struct.unpack_from("<" + "h" * count, data, 0)
        idx = 0
        if count < 6:
            return
        idx += 5  # header
        while idx < count:
            grh_id = values[idx]
            idx += 1
            if grh_id == 0:
                break
            if idx >= count:
                break
            num_frames = values[idx]
            idx += 1
            if num_frames > 1:
                if idx + num_frames > count:
                    break
                frames = list(values[idx : idx + num_frames])
                idx += num_frames
                if idx >= count:
                    break
                speed = values[idx]
                idx += 1
                entry = GrhEntry(
                    id=int(grh_id),
                    num_frames=int(num_frames),
                    frames=[int(v) for v in frames],
                    speed=int(speed),
                    file_num=0,
                    sx=0,
                    sy=0,
                    w=0,
                    h=0,
                    tile_w=0.0,
                    tile_h=0.0,
                )
            else:
                if idx + 5 > count:
                    break
                file_num = values[idx]
                sx = values[idx + 1]
                sy = values[idx + 2]
                w = values[idx + 3]
                h = values[idx + 4]
                idx += 5
                entry = GrhEntry(
                    id=int(grh_id),
                    num_frames=int(num_frames),
                    frames=[],
                    speed=0,
                    file_num=int(file_num),
                    sx=int(sx),
                    sy=int(sy),
                    w=int(w),
                    h=int(h),
                    tile_w=float(w) / 32.0,
                    tile_h=float(h) / 32.0,
                )
            self.entries[entry.id] = entry

    def resolve(self, grh_id: int, t: float) -> Optional[GrhEntry]:
        entry = self.entries.get(grh_id)
        if not entry:
            return None
        if entry.num_frames > 1 and entry.frames:
            frame_duration = max(0.05, float(entry.speed) * 0.04)
            frame = int(t / frame_duration) % max(1, entry.num_frames)
            frame = max(0, min(frame, len(entry.frames) - 1))
            frame_id = entry.frames[frame]
            return self.entries.get(frame_id, entry)
        return entry


class LegacyMap:
    def __init__(self, map_id: int, map_path: Path, inf_path: Path, obj_path: Path) -> None:
        self.map_id = map_id
        self.map_path = map_path
        self.inf_path = inf_path
        self.obj_path = obj_path

        self.width = 0
        self.height = 0
        self.blocked: List[List[int]] = []
        self.g1: List[List[int]] = []
        self.g2: List[List[int]] = []
        self.g3: List[List[int]] = []
        self.exit_map: List[List[int]] = []
        self.exit_x: List[List[int]] = []
        self.exit_y: List[List[int]] = []

        self._load()

    def _load(self) -> None:
        if self.map_path.exists():
            data = self.map_path.read_bytes()
            stride = 7
            tiles = len(data) // stride
            side = int(math.sqrt(tiles))
            self.width = side
            self.height = side
            self.blocked = [[0] * self.width for _ in range(self.height)]
            self.g1 = [[0] * self.width for _ in range(self.height)]
            self.g2 = [[0] * self.width for _ in range(self.height)]
            self.g3 = [[0] * self.width for _ in range(self.height)]

            off = 0
            for y in range(self.height):
                for x in range(self.width):
                    if off + stride <= len(data):
                        b = data[off]
                        v1, v2, v3 = struct.unpack_from("<hhh", data, off + 1)
                    else:
                        b, v1, v2, v3 = 0, 0, 0, 0
                    off += stride
                    self.blocked[y][x] = int(b)
                    self.g1[y][x] = int(v1)
                    self.g2[y][x] = int(v2)
                    self.g3[y][x] = int(v3)

        if self.inf_path.exists() and self.width > 0:
            data = self.inf_path.read_bytes()
            tiles = self.width * self.height
            stride = len(data) // tiles if tiles > 0 else 0
            if stride <= 0:
                stride = 16
            fields = stride // 2
            fmt = "<" + "h" * fields
            self.exit_map = [[0] * self.width for _ in range(self.height)]
            self.exit_x = [[0] * self.width for _ in range(self.height)]
            self.exit_y = [[0] * self.width for _ in range(self.height)]
            off = 0
            for y in range(self.height):
                for x in range(self.width):
                    if off + stride <= len(data):
                        vals = list(struct.unpack_from(fmt, data, off))
                    else:
                        vals = [0] * fields
                    off += stride
                    if len(vals) >= 3:
                        self.exit_map[y][x] = int(vals[0])
                        self.exit_x[y][x] = int(vals[1])
                        self.exit_y[y][x] = int(vals[2])


class GrhCache:
    def __init__(self, grh_dirs: List[Path]) -> None:
        self.grh_dirs = grh_dirs
        self.cache: Dict[int, QtGui.QImage] = {}
        self.mask_cache: Dict[int, QtGui.QImage] = {}

    def _find_file(self, file_num: int) -> Optional[Path]:
        names = [f"grh{file_num}.bmp", f"Grh{file_num}.bmp", f"GRH{file_num}.BMP"]
        for root in self.grh_dirs:
            for name in names:
                path = root / name
                if path.exists():
                    return path
        return None

    def _find_mask(self, file_num: int) -> Optional[Path]:
        names = [
            f"grh{file_num}M.bmp",
            f"Grh{file_num}M.bmp",
            f"GRH{file_num}M.BMP",
        ]
        for root in self.grh_dirs:
            for name in names:
                path = root / name
                if path.exists():
                    return path
        return None

    def _apply_color_key(self, img: QtGui.QImage) -> QtGui.QImage:
        img = img.convertToFormat(QtGui.QImage.Format_ARGB32)
        key = QtGui.QColor(img.pixel(0, 0))
        for y in range(img.height()):
            for x in range(img.width()):
                c = QtGui.QColor(img.pixel(x, y))
                if c.red() == key.red() and c.green() == key.green() and c.blue() == key.blue():
                    c.setAlpha(0)
                    img.setPixelColor(x, y, c)
        return img

    def _apply_mask(self, img: QtGui.QImage, mask: QtGui.QImage) -> QtGui.QImage:
        img = img.convertToFormat(QtGui.QImage.Format_ARGB32)
        mask = mask.convertToFormat(QtGui.QImage.Format_ARGB32)
        if mask.size() != img.size():
            mask = mask.scaled(img.size(), QtCore.Qt.IgnoreAspectRatio, QtCore.Qt.FastTransformation)
        for y in range(img.height()):
            for x in range(img.width()):
                mc = QtGui.QColor(mask.pixel(x, y))
                lum = (mc.red() + mc.green() + mc.blue()) / 3.0
                a = max(0, min(255, int(255 - lum)))
                c = QtGui.QColor(img.pixel(x, y))
                c.setAlpha(a)
                img.setPixelColor(x, y, c)
        return img

    def get(self, file_num: int) -> Optional[QtGui.QImage]:
        if file_num in self.cache:
            return self.cache[file_num]
        path = self._find_file(file_num)
        if not path:
            self.cache[file_num] = None
            return None
        img = QtGui.QImage(str(path))
        if img.isNull():
            self.cache[file_num] = None
            return None
        mask_path = self._find_mask(file_num)
        if mask_path:
            mask = QtGui.QImage(str(mask_path))
            if not mask.isNull():
                img = self._apply_mask(img, mask)
            else:
                img = self._apply_color_key(img)
        else:
            img = self._apply_color_key(img)
        self.cache[file_num] = img
        return img


class MapCanvas(QtWidgets.QWidget):
    tile_hovered = QtCore.Signal(int, int)

    def __init__(self, grh_db: GrhDatabase, grh_cache: GrhCache) -> None:
        super().__init__()
        self.grh_db = grh_db
        self.grh_cache = grh_cache
        self.map: Optional[LegacyMap] = None
        self.zoom = 1.0
        self.offset = QtCore.QPointF(0.0, 0.0)
        self.dragging = False
        self.last_mouse = QtCore.QPointF(0.0, 0.0)
        self.show_layer = [True, True, True]
        self.show_blocked = True
        self.show_exits = True
        self.setMouseTracking(True)

    def set_map(self, legacy_map: LegacyMap) -> None:
        self.map = legacy_map
        self.offset = QtCore.QPointF(0.0, 0.0)
        self.zoom = 1.0
        self.update()

    def paintEvent(self, event: QtGui.QPaintEvent) -> None:
        if not self.map:
            return
        painter = QtGui.QPainter(self)
        painter.setRenderHint(QtGui.QPainter.SmoothPixmapTransform, False)
        painter.fillRect(self.rect(), QtGui.QColor(24, 24, 28))

        t = time.time()
        size = TILE_SIZE * self.zoom
        if size <= 1:
            return

        view_w = self.width()
        view_h = self.height()

        start_x = max(0, int((-self.offset.x()) / size))
        start_y = max(0, int((-self.offset.y()) / size))
        end_x = min(self.map.width, int((view_w - self.offset.x()) / size) + 2)
        end_y = min(self.map.height, int((view_h - self.offset.y()) / size) + 2)

        for y in range(start_y, end_y):
            for x in range(start_x, end_x):
                screen_x = self.offset.x() + x * size
                screen_y = self.offset.y() + y * size
                dest = QtCore.QRectF(screen_x, screen_y, size, size)

                for layer_index, layer in enumerate([self.map.g1, self.map.g2, self.map.g3]):
                    if not self.show_layer[layer_index]:
                        continue
                    grh_id = layer[y][x]
                    if grh_id > 0:
                        entry = self.grh_db.resolve(grh_id, t)
                        if entry and entry.file_num > 0:
                            img = self.grh_cache.get(entry.file_num)
                            if img:
                                src = QtCore.QRect(entry.sx, entry.sy, entry.w, entry.h)
                                dest_w = entry.w * self.zoom
                                dest_h = entry.h * self.zoom
                                dx = screen_x
                                dy = screen_y
                                if entry.tile_w != 1.0:
                                    dx -= (entry.tile_w * TILE_SIZE * 0.5 - TILE_SIZE * 0.5) * self.zoom
                                if entry.tile_h != 1.0:
                                    dy -= (entry.tile_h * TILE_SIZE - TILE_SIZE) * self.zoom
                                painter.drawImage(QtCore.QRectF(dx, dy, dest_w, dest_h), img, src)

                if self.show_blocked and self.map.blocked[y][x] == 1:
                    painter.fillRect(dest, QtGui.QColor(255, 40, 40, 90))
                if self.show_exits and self.map.exit_map and self.map.exit_map[y][x] > 0:
                    painter.fillRect(dest, QtGui.QColor(80, 200, 255, 90))

    def wheelEvent(self, event: QtGui.QWheelEvent) -> None:
        delta = event.angleDelta().y() / 120.0
        if delta == 0:
            return
        old_zoom = self.zoom
        self.zoom = max(0.2, min(4.0, self.zoom * (1.1 ** delta)))
        pos = event.position()
        if old_zoom != self.zoom:
            scale = self.zoom / old_zoom
            self.offset = pos + (self.offset - pos) * scale
        self.update()

    def mousePressEvent(self, event: QtGui.QMouseEvent) -> None:
        if event.button() in (QtCore.Qt.MiddleButton, QtCore.Qt.RightButton):
            self.dragging = True
            self.last_mouse = event.position()

    def mouseReleaseEvent(self, event: QtGui.QMouseEvent) -> None:
        if event.button() in (QtCore.Qt.MiddleButton, QtCore.Qt.RightButton):
            self.dragging = False

    def mouseMoveEvent(self, event: QtGui.QMouseEvent) -> None:
        if self.dragging:
            delta = event.position() - self.last_mouse
            self.offset += delta
            self.last_mouse = event.position()
            self.update()
        else:
            if self.map:
                size = TILE_SIZE * self.zoom
                if size > 0:
                    x = int((event.position().x() - self.offset.x()) / size)
                    y = int((event.position().y() - self.offset.y()) / size)
                    if 0 <= x < self.map.width and 0 <= y < self.map.height:
                        self.tile_hovered.emit(x, y)


class MainWindow(QtWidgets.QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("Legacy Map Viewer")
        self.resize(1024, 768)

        self.grh_db = GrhDatabase(GRH_DAT)
        self.grh_cache = GrhCache(GRH_DIRS)
        self.canvas = MapCanvas(self.grh_db, self.grh_cache)
        self.setCentralWidget(self.canvas)

        self.map_selector = QtWidgets.QComboBox()
        self._populate_maps()
        self.map_selector.currentIndexChanged.connect(self._change_map)

        toolbar = QtWidgets.QToolBar("View")
        self.addToolBar(toolbar)
        toolbar.addWidget(QtWidgets.QLabel("Map:"))
        toolbar.addWidget(self.map_selector)

        self.layer_checks = []
        for i in range(3):
            chk = QtWidgets.QCheckBox(f"L{i+1}")
            chk.setChecked(True)
            chk.stateChanged.connect(self._update_layers)
            toolbar.addWidget(chk)
            self.layer_checks.append(chk)

        self.blocked_chk = QtWidgets.QCheckBox("Blocked")
        self.blocked_chk.setChecked(True)
        self.blocked_chk.stateChanged.connect(self._update_layers)
        toolbar.addWidget(self.blocked_chk)

        self.exit_chk = QtWidgets.QCheckBox("Exits")
        self.exit_chk.setChecked(True)
        self.exit_chk.stateChanged.connect(self._update_layers)
        toolbar.addWidget(self.exit_chk)

        self.status = QtWidgets.QStatusBar()
        self.setStatusBar(self.status)
        self.canvas.tile_hovered.connect(self._show_tile_info)

        if self.map_selector.count() > 0:
            self._change_map(0)

    def _populate_maps(self) -> None:
        maps = []
        for path in MAPS_DIR.glob("Map*.map"):
            name = path.stem
            try:
                map_id = int(name.replace("Map", ""))
            except ValueError:
                continue
            maps.append((map_id, path))
        for map_id, _ in sorted(maps):
            self.map_selector.addItem(f"Map {map_id}", map_id)

    def _change_map(self, index: int) -> None:
        if index < 0:
            return
        map_id = self.map_selector.currentData()
        if map_id is None:
            return
        map_path = MAPS_DIR / f"Map{map_id}.map"
        inf_path = MAPS_DIR / f"Map{map_id}.inf"
        obj_path = MAPS_DIR / f"Map{map_id}.obj"
        legacy_map = LegacyMap(map_id, map_path, inf_path, obj_path)
        self.canvas.set_map(legacy_map)

    def _update_layers(self) -> None:
        self.canvas.show_layer = [chk.isChecked() for chk in self.layer_checks]
        self.canvas.show_blocked = self.blocked_chk.isChecked()
        self.canvas.show_exits = self.exit_chk.isChecked()
        self.canvas.update()

    def _show_tile_info(self, x: int, y: int) -> None:
        if not self.canvas.map:
            return
        m = self.canvas.map
        info = f"Tile {x},{y} | L1:{m.g1[y][x]} L2:{m.g2[y][x]} L3:{m.g3[y][x]}"
        if m.exit_map and m.exit_map[y][x] > 0:
            info += f" | Exit: {m.exit_map[y][x]} ({m.exit_x[y][x]},{m.exit_y[y][x]})"
        if m.blocked[y][x] == 1:
            info += " | Blocked"
        self.status.showMessage(info)


def main() -> None:
    app = QtWidgets.QApplication([])
    window = MainWindow()
    window.show()
    app.exec()


if __name__ == "__main__":
    main()
