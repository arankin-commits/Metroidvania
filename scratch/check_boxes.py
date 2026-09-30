from PIL import Image
import numpy as np

def check_label_erasure(name, label_boxes):
    im = Image.open('assets/references/forest_boss_summons/' + name)
    arr = np.array(im)
    bg = arr[0,0].astype(float)
    diff = np.sqrt(np.sum((arr.astype(float) - bg)**2, axis=2))
    
    print(f"\n=== {name} ===")
    for r, (x1, y1, x2, y2) in enumerate(label_boxes):
        box_diff = diff[y1:y2, x1:x2]
        # check character pixels vs text pixels
        # text pixels are typically bright white/light gray/cyan
        # character pixels are brown/green/earth colors
        print(f"Row {r} label box ({x1},{y1})-({x2},{y2}): mean diff={box_diff.mean():.1f}, max diff={box_diff.max():.1f}")

# Rough label boxes per row
check_label_erasure('earthen bear.png', [
    (0, 0, 150, 35),
    (0, 217, 140, 217+35),
    (0, 434, 140, 434+35),
    (0, 651, 200, 651+35),
    (0, 868, 200, 868+35)
])
