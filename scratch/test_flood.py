from PIL import Image
import numpy as np
from collections import deque

def flood_fill_bg(im, tolerance=24.0):
    arr = np.array(im)
    h, w, _ = arr.shape
    bg = arr[0, 0].astype(float)
    
    # distance to bg
    diff = np.sqrt(np.sum((arr.astype(float) - bg)**2, axis=2))
    
    # BFS from all borders
    is_bg = np.zeros((h, w), dtype=bool)
    q = deque()
    
    # seed with borders where diff < tolerance
    for x in range(w):
        if diff[0, x] < tolerance:
            is_bg[0, x] = True
            q.append((0, x))
        if diff[h-1, x] < tolerance:
            is_bg[h-1, x] = True
            q.append((h-1, x))
    for y in range(h):
        if diff[y, 0] < tolerance and not is_bg[y, 0]:
            is_bg[y, 0] = True
            q.append((y, 0))
        if diff[y, w-1] < tolerance and not is_bg[y, w-1]:
            is_bg[y, w-1] = True
            q.append((y, w-1))
            
    while q:
        cy, cx = q.popleft()
        for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w:
                if not is_bg[ny, nx] and diff[ny, nx] < tolerance:
                    is_bg[ny, nx] = True
                    q.append((ny, nx))
                    
    # Create RGBA image
    rgba = np.zeros((h, w, 4), dtype=np.uint8)
    rgba[:, :, :3] = arr[:, :, :3]
    # Smooth alpha near edges
    alpha = np.ones((h, w), dtype=np.float32) * 255.0
    alpha[is_bg] = 0.0
    
    # also for pixels connected to bg with diff between tolerance and tolerance + 12, blend alpha
    rgba[:, :, 3] = alpha.astype(np.uint8)
    return Image.fromarray(rgba)

for name, short in [('earthen bear.png', 'bear'), ('earthen troll.png', 'troll'), ('tree ent.png', 'ent')]:
    im = Image.open('assets/references/forest_boss_summons/' + name)
    out = flood_fill_bg(im, tolerance=26.0)
    out.save(f'scratch_{short}_test_alpha.png')
    print(f"Generated scratch_{short}_test_alpha.png successfully")
