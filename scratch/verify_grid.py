from PIL import Image
import numpy as np

def verify_grid(name, row_counts):
    im = Image.open('assets/references/forest_boss_summons/' + name)
    arr = np.array(im)
    bg = arr[0,0].astype(float)
    diff = np.sqrt(np.sum((arr.astype(float) - bg)**2, axis=2))
    
    print(f"\n=================== {name} ===================")
    for r, count in enumerate(row_counts):
        y1 = int(r * 1086.0 / 5.0)
        y2 = int((r + 1) * 1086.0 / 5.0)
        cell_w = 1448.0 / count
        print(f"Row {r} ({count} frames): y={y1}..{y2}, cell_w={cell_w:.1f}")
        for c in range(count):
            x1 = int(c * cell_w)
            x2 = int((c + 1) * cell_w)
            cell_diff = diff[y1:y2, x1:x2]
            # find bbox in this cell
            mask = cell_diff > 20
            ys, xs = np.where(mask)
            if len(xs) > 0:
                # bbox inside cell
                bx1, bx2 = xs.min(), xs.max()
                by1, by2 = ys.min(), ys.max()
                center_x = (bx1 + bx2) / 2.0
                print(f"  Frame {c}: x={x1:4d}..{x2:4d}, sprite inside: x={bx1:3d}..{bx2:3d} (w={bx2-bx1:3d}), center={center_x:.1f}/{cell_w:.1f}, y={by1:3d}..{by2:3d} (h={by2-by1:3d})")
            else:
                print(f"  Frame {c}: EMPTY")

verify_grid('earthen bear.png', [6, 8, 8, 8, 6])
verify_grid('earthen troll.png', [6, 6, 6, 6, 6])
verify_grid('tree ent.png', [6, 8, 8, 8, 6])
