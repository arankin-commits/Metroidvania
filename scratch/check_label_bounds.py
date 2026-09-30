from PIL import Image
import numpy as np

def check_label_and_frame0(name):
    im = Image.open('assets/references/forest_boss_summons/' + name)
    arr = np.array(im)
    bg = arr[0,0].astype(float)
    diff = np.sqrt(np.sum((arr.astype(float) - bg)**2, axis=2))
    
    print(f"\n=== {name} ===")
    for r in range(5):
        y1 = int(r * 1086 / 5)
        y2 = int((r + 1) * 1086 / 5)
        # Look at the first 300 columns of this row
        sub_diff = diff[y1:y2, :350]
        # check vertical projection in this sub region
        v_proj = sub_diff.mean(axis=0)
        # print columns where there's content vs gap
        active_cols = np.where(v_proj > 15)[0]
        # find gap between label and sprite
        # label is small height text near top of row (y < y1 + 45)
        text_zone = diff[y1:y1+35, :200]
        text_cols = np.where(text_zone.mean(axis=0) > 15)[0]
        if len(text_cols) > 0:
            print(f"Row {r} (y={y1}): Text cols {text_cols[0]}..{text_cols[-1]}")
        else:
            print(f"Row {r} (y={y1}): No text detected")

for name in ['earthen bear.png', 'earthen troll.png', 'tree ent.png']:
    check_label_and_frame0(name)
