from PIL import Image, ImageDraw
import numpy as np

def make_clean_sheet(src_name, dst_name, thresh=32):
    im = Image.open('assets/references/forest_boss_summons/' + src_name).convert('RGBA')
    w, h = im.size
    bg = im.getpixel((0, 0))
    
    # 1. Erase text labels in frame 0 of each row
    draw = ImageDraw.Draw(im)
    for r in range(5):
        y1 = int(r * 1086.0 / 5.0)
        # Erase text area in top-left of row
        draw.rectangle([0, y1, 210, y1 + 34], fill=bg)
        
    # 2. Floodfill background from borders
    for x in range(0, w, 10):
        if im.getpixel((x, 0))[3] > 0:
            ImageDraw.floodfill(im, (x, 0), (0, 0, 0, 0), thresh=thresh)
        if im.getpixel((x, h-1))[3] > 0:
            ImageDraw.floodfill(im, (x, h-1), (0, 0, 0, 0), thresh=thresh)
    for y in range(0, h, 10):
        if im.getpixel((0, y))[3] > 0:
            ImageDraw.floodfill(im, (0, y), (0, 0, 0, 0), thresh=thresh)
        if im.getpixel((w-1, y))[3] > 0:
            ImageDraw.floodfill(im, (w-1, y), (0, 0, 0, 0), thresh=thresh)
            
    # Also floodfill internal gaps between frames along the row boundary if any
    for r in range(1, 5):
        y = int(r * 1086.0 / 5.0)
        for x in range(0, w, 40):
            if im.getpixel((x, y))[3] > 0:
                # check if it's near bg color
                p = im.getpixel((x, y))
                dist = sum((p[i] - bg[i])**2 for i in range(3))**0.5
                if dist < thresh:
                    ImageDraw.floodfill(im, (x, y), (0, 0, 0, 0), thresh=thresh)
                    
    out_path = 'assets/characters/' + dst_name
    im.save(out_path)
    arr = np.array(im)[:, :, 3]
    print(f"Generated {out_path}: {np.mean(arr == 0)*100:.1f}% transparent")

make_clean_sheet('earthen bear.png', 'summon_bear.png', thresh=32)
make_clean_sheet('earthen troll.png', 'summon_troll.png', thresh=32)
make_clean_sheet('tree ent.png', 'summon_ent.png', thresh=32)
