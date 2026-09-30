"""Pack the supplied forest summon poses into registered, transparent animation cells."""

from pathlib import Path
from collections import deque

from PIL import Image
import numpy as np


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design/references/forest-boss"
OUTPUT = ROOT / "assets/characters"
CELL = 320
FOOT_Y = 300

# The row bands exclude storyboard headings, frame numbers, and dividing rules.
# Each tuple is (first body row, last body row, frame count).
SHEETS = {
    "bear": [(29, 177, 6), (245, 386, 8), (455, 587, 8), (663, 806, 8), (898, 1036, 6)],
    "troll": [(25, 177, 6), (205, 367, 6), (399, 557, 6), (583, 817, 6), (877, 1048, 6)],
    "ent": [(40, 207, 6), (264, 417, 8), (472, 626, 8), (698, 827, 12), (900, 1037, 6)],
}
FACE_X = {
    "bear": [[186, 411, 649, 885, 1112, 1344], [171, 350, 515, 692, 873, 1063, 1222, 1403], [174, 346, 529, 708, 901, 1074, 1239, 1409], [145, 322, 522, 666, 901, 1062, 1234, 1409], [201, 416, 635, 887, 1125, 1367]],
    "troll": [[182, 412, 641, 875, 1097, 1325], [200, 413, 630, 858, 1094, 1337], [227, 451, 644, 863, 1118, 1368], [185, 393, 593, 821, 1046, 1378], [172, 420, 650, 897, 1121, 1377]],
    "ent": [[132, 365, 598, 827, 1069, 1313], [138, 324, 497, 679, 862, 1048, 1229, 1401], [154, 334, 494, 669, 846, 1022, 1199, 1377], [79, 205, 324, 479, 535, 648, 762, 953, 978, 1166, 1166, 1395], [147, 371, 598, 871, 1093, 1318]],
}


def pose_component(source: np.ndarray, top: int, bottom: int, face_x: int, kind: str, row: int, frame: int) -> Image.Image:
    region = source[top:bottom]
    opaque = region[:, :, 3] > 70
    cyan = (region[:, :, 2] > 130) & (region[:, :, 1] > 110) & (region[:, :, 0] < 100) & opaque
    first_y = 80 if kind == "troll" and row == 3 and frame == 0 else 20
    nearby = cyan[first_y:, max(0, face_x - 13):min(1448, face_x + 14)]
    ys, xs = np.where(nearby)
    assert len(xs), (kind, row, face_x)
    xs += max(0, face_x - 13)
    ys += first_y
    nearest = int(np.argmin(abs(xs - face_x)))
    seed = (int(ys[nearest]), int(xs[nearest]))
    visited = np.zeros(opaque.shape, dtype=bool)
    visited[seed] = True
    queue = deque([seed])
    while queue:
        y, x = queue.popleft()
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (1, -1), (-1, 1), (-1, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < opaque.shape[0] and 0 <= nx < 1448 and opaque[ny, nx] and not visited[ny, nx]:
                visited[ny, nx] = True
                queue.append((ny, nx))
    pixels = region.copy()
    pixels[~visited] = 0
    pose = Image.fromarray(pixels, "RGBA")
    bounds = pose.getbbox()
    assert bounds, (kind, row, face_x)
    return pose.crop(bounds)


def pack(kind: str, rows: list[tuple[int, int, int]]) -> None:
    source = np.array(Image.open(SOURCE / f"summon-{kind}-matte.png").convert("RGBA"))
    assert source.shape == (1086, 1448, 4)
    columns = max(count for _, _, count in rows)
    atlas = Image.new("RGBA", (columns * CELL, len(rows) * CELL))
    for row, (top, bottom, count) in enumerate(rows):
        for frame in range(count):
            pose = pose_component(source, top, bottom, FACE_X[kind][row][frame], kind, row, frame)
            if pose.width > CELL - 8:
                pose = pose.resize((CELL - 8, round(pose.height * (CELL - 8) / pose.width)), Image.Resampling.NEAREST)
            assert pose.height <= FOOT_Y, (kind, row, frame, pose.size)
            x = frame * CELL + (CELL - pose.width) // 2
            y = row * CELL + FOOT_Y - pose.height
            atlas.alpha_composite(pose, (x, y))
    if kind == "troll":
        # The source sheet's first moving/recoil panels contain a black horizontal
        # storyboard cut through the body. Reuse the adjacent intact authored pose.
        for target_row, source_row, source_frame in [(1, 1, 1), (2, 2, 1), (3, 0, 0), (4, 4, 1)]:
            replacement = atlas.crop((source_frame * CELL, source_row * CELL, (source_frame + 1) * CELL, (source_row + 1) * CELL))
            atlas.paste(Image.new("RGBA", (CELL, CELL)), (0, target_row * CELL))
            atlas.alpha_composite(replacement, (0, target_row * CELL))
    path = OUTPUT / f"summon_{kind}_atlas.png"
    atlas.save(path)
    print(f"{kind}: {sum(r[2] for r in rows)} frames, {atlas.size}, {path}")


if __name__ == "__main__":
    for name, bands in SHEETS.items():
        pack(name, bands)
