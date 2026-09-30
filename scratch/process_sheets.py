from PIL import Image
import numpy as np

def process_sheet(name, short, row_counts):
    im = Image.open('assets/references/forest_boss_summons/' + name)
    arr = np.array(im)
    h, w, _ = arr.shape
    bg = arr[0, 0].astype(float)
    
    # 1. Erase text labels in frame 0 of each row
    for r in range(5):
        y1 = int(r * 1086.0 / 5.0)
        # Erase text area in top-left of row
        # In Troll row 3/4, text might be slightly different or labels
        arr[y1:y1+34, 0:210] = bg.astype(np.uint8)
        
    # 2. Chroma key background to transparent
    # Distance to background color
    diff = np.sqrt(np.sum((arr.astype(float) - bg)**2, axis=2))
    
    # Create RGBA
    rgba = np.zeros((h, w, 4), dtype=np.uint8)
    rgba[:, :, :3] = arr[:, :, :3]
    
    # Smooth alpha transition between distance 18 and 30
    alpha = np.clip((diff - 18.0) / (30.0 - 18.0), 0.0, 1.0) * 255.0
    rgba[:, :, 3] = alpha.astype(np.uint8)
    
    out_im = Image.fromarray(rgba, 'RGBA')
    out_path = f'assets/characters/summon_{short}.png'
    out_im.save(out_path)
    print(f"Saved {out_path} ({w}x{h})")

process_sheet('earthen bear.png', 'bear', [6, 8, 8, 8, 6])
process_sheet('earthen troll.png', 'troll', [6, 6, 6, 6, 6])
process_sheet('tree ent.png', 'ent', [6, 8, 8, 8, 6])
