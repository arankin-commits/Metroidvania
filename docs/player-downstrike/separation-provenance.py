from pathlib import Path
from PIL import Image
import shutil,json,hashlib,zipfile
root=Path('outputs/player-downstrike')
(root/'sprites').mkdir(exist_ok=True)
(root/'reference').mkdir(exist_ok=True)
source=Path('C:/Users/kvong/.codex/generated_images/01a0f951-09ff-77c0-8858-08d2c0b221b3/exec-36fe23ff-3143-4560-a4a0-b34eca36dbe9.png')
shutil.copy2(source,root/'reference/downstrike-source-atlas.png')
im=Image.open(source).convert('RGBA')
keys=['windup_01','windup_02','windup_03','windup_04','plunge_01','plunge_02','impact_01','impact_02','recover_01','recover_02','recover_03','idle']
rects=[(40,218,314,392),(426,135,629,347),(798,95,992,380),(1145,77,1371,382),(86,409,293,751),(464,413,683,722),(777,543,1045,751),(1145,590,1398,753),(63,844,329,1036),(426,803,666,1035),(793,792,997,1039),(1174,798,1370,1039)]
contacts=[(205,383),(550,337),(945,370),(1296,370),(240,741),(583,711),(900,742),(1275,743),(201,1026),(563,1026),(931,1026),(1290,1026)]
frames=[]
for key,rect,contact in zip(keys,rects,contacts):
    sprite=im.crop(rect)
    out=Image.new('RGBA',(512,512))
    offset=(256-(contact[0]-rect[0]),420-(contact[1]-rect[1]))
    assert offset[0]>=0 and offset[1]>=0 and offset[0]+sprite.width<=512 and offset[1]+sprite.height<=512
    out.paste(sprite,offset)
    out.save(root/'sprites'/f'{key}.png')
    alpha=out.getchannel('A')
    assert alpha.getextrema()==(0,255)
    frames.append({'key':key,'path':key+'.png','source_rect':rect,'source_contact':contact,'canvas_contact':[256,420], 'contact_note':'boot/body floor contact for every pose; fist impact ahead of feet; hand calibrated approximation'})
manifest={'canvas':[512,512],'contact_y_offset':164,'demo_scale':.22,'frames':frames,'status':'AI-generated static key poses separated without repainting/rescaling; refine anatomy and pose contacts in game','clips':{'slam_windup':{'keys':keys[:4],'seconds':.14},'slam_plunge':{'keys':keys[4:6],'frame_seconds':.08,'loop':True},'slam_land':{'keys':keys[6:11],'seconds':.30},'idle_reference':{'keys':['idle']}}}
(root/'sprites/manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
(root/'reference/generation-prompt.txt').write_text('Use both attached images as character and pixel-art style REFERENCES only. Make a NEW transparent sprite animation atlas for a TWO-HANDED GROUND SMASH, explicitly NOT a sword stab. Match small hooded side-view adventurer proportions of complete sheet: navy hood with single amber eye, cyan scarf cape, dark compact segmented armor, boots, gloves and small brass details. Healthy base version: no red injury accents and no violet injury particles. Sword stays SHEATHED, no blade in hands at any time. 4 columns x 3 rows, exactly twelve well-isolated full-body poses with clear gutters, no labels or guide lines or scenery. Crisp low-resolution pixel-art, limited colors, no painted gradients. Face right consistently, compact limbs, same character body size each frame. Row1 frames: crouch arms drawn back, airborne coil fists together at chest, raise clasped fists overhead, poised overhead fists bent knees. Row2: vertical feet-first descent knees bent TWO fists overhead cape streaming upward, second descent variation arms beginning downward hammer motion, ground impact deep squat BOTH CLOSED HANDS smashing floor in front of boots (NO WEAPON), compressed followthrough two fists on ground. Row3: fists lifting from floor, rising from squat, straightening arms lowered, healthy sheathed idle. Clear silhouette read of fist hammer smash like a ground-pound; not stabbing, not sword slash. Keep every full cape/limb inside its own cell. NO dust or shockwaves baked in, effects generated separately in engine. transparent RGBA background.',encoding='utf-8')
shutil.copy2(__file__,root/'reference/separation-provenance.py')
files=[p for p in root.rglob('*') if p.is_file() and '.godot' not in p.parts and p.suffix not in ('.uid','.import') and p.name!='PACKAGE_INVENTORY.json']
(root/'PACKAGE_INVENTORY.json').write_text(json.dumps({'files':[{'path':p.relative_to(root).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in files]},indent=2),encoding='utf-8')
target=Path('outputs/player-downstrike-ability.zip')
with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED) as z:
    for p in files+[root/'PACKAGE_INVENTORY.json']: z.write(p,Path(root.name)/p.relative_to(root))
with zipfile.ZipFile(target) as z: assert z.testzip() is None
print(f'{len(files)+1} files; alpha and archive CRC verified; {target}')
