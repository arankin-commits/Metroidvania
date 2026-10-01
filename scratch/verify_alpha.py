from PIL import Image
import numpy as np

for short in ['bear', 'troll', 'ent']:
    path = f'assets/characters/summon_{short}.png'
    im = Image.open(path)
    arr = np.array(im)
    alpha = arr[:, :, 3]
    print(f"=== {path} ===")
    print("Shape:", arr.shape)
    print("Transparent pixel percentage:", np.mean(alpha == 0) * 100)
    print("Opaque pixel percentage:", np.mean(alpha == 255) * 100)
    print("Border pixels alpha sum (should be 0):", alpha[0, :].sum() + alpha[-1, :].sum() + alpha[:, 0].sum() + alpha[:, -1].sum())
