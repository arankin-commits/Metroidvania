from PIL import Image

for name, short in [('earthen bear.png', 'bear'), ('earthen troll.png', 'troll'), ('tree ent.png', 'ent')]:
    im = Image.open('assets/references/forest_boss_summons/' + name)
    # Save crops of the first 250x217 px of rows 0..4
    for r in range(5):
        y1 = int(r * 1086 / 5)
        y2 = int((r + 1) * 1086 / 5)
        crop = im.crop((0, y1, 260, y2))
        crop.save(f'scratch_{short}_r{r}_f0.png')
print("Saved all rX_f0 crops")
