from PIL import Image
import numpy as np

def inspect_crop(filename):
    im = Image.open(filename)
    arr = np.array(im)
    bg = arr[0, 0].astype(float)
    diff = np.sqrt(np.sum((arr.astype(float) - bg)**2, axis=2))
    print(f"\n=== {filename} ===")
    # Print a 40x25 character grid representation
    step_y = arr.shape[0] // 20
    step_x = arr.shape[1] // 40
    for y in range(0, arr.shape[0], step_y):
        row_str = ""
        for x in range(0, arr.shape[1], step_x):
            d = diff[y:y+step_y, x:x+step_x].mean()
            row_str += "#" if d > 20 else "."
        if row_str.strip("."):
            print(f"{y:3d}: {row_str}")

for short in ['bear', 'troll', 'ent']:
    for r in range(5):
        inspect_crop(f'scratch_{short}_r{r}_f0.png')
