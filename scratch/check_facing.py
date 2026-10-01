from PIL import Image
import numpy as np

# In row 1 (walk), check horizontal movement or face direction
# E.g., for bear and troll, is the front of the body on the right or left?
im = Image.open('assets/characters/summon_bear.png')
# crop frame 1 of row 1 (walk)
frame1 = im.crop((181, 217, 362, 434))
frame1.save('scratch_bear_walk1.png')

im_troll = Image.open('assets/characters/summon_troll.png')
frame1_t = im_troll.crop((241, 217, 482, 434))
frame1_t.save('scratch_troll_walk1.png')

print("Saved walk frames to check facing")
