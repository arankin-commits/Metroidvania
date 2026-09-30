from PIL import Image
import numpy as np

def inspect_frame0(name):
    im = Image.open('assets/references/forest_boss_summons/' + name)
    arr = np.array(im)
    bg = arr[0,0].astype(float)
    diff = np.sqrt(np.sum((arr.astype(float) - bg)**2, axis=2))
    print(f"\n=== {name} ===")
    for r in range(5):
        y1 = int(r * 1086 / 5)
        y2 = int((r + 1) * 1086 / 5)
        # Check slice of frame 0 (x: 0..240)
        # check y distribution
        frame0 = diff[y1:y2, 0:240]
        y_proj = frame0.mean(axis=1)
        active_y = np.where(y_proj > 10)[0]
        if len(active_y) > 0:
            print(f"Row {r}: active y relative to row start: {active_y[0]}..{active_y[-1]} (row height is {y2-y1})")

for name in ['earthen bear.png', 'earthen troll.png', 'tree ent.png']:
    inspect_frame0(name)
