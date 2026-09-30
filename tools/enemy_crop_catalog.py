"""Write measured storyboard regions (metadata only; Godot assembles pixels)."""
import json
from pathlib import Path

enemies = {}
def enemy(name, height, source_height, collider):
    enemies[name] = dict(height=height, scale=height/source_height, collider=collider, animations={})
def row(name, anim, source, top, bottom, edges, centers, feet, fps=9, loop=False, scale=None):
    frames=[]
    for i, center in enumerate(centers):
        frames.append(dict(source=source, rect=[edges[i],top,edges[i+1]-edges[i],bottom-top],
                           pivot=[center, feet[i] if isinstance(feet,list) else feet]))
        if scale: frames[-1]['scale']=scale
    enemies[name]['animations'][anim]=dict(fps=fps,loop=loop,frames=frames)

enemy('goblin',58,112,[30,56])
row('goblin','sleep','goblin',60,212,[25,260,496,729,965,1195,1447],[145,378,610,849,1083,1316],191,6,True)
row('goblin','wake','goblin',252,430,[25,249,455,650,850,1049,1246,1447],[123,358,549,745,950,1154,1344],398,9)
row('goblin','idle','goblin',485,639,[25,247,452,640,817,997,1200],[126,336,540,730,907,1080],611,6,True)
row('goblin','walk','goblin',690,851,[20,142,257,365,476,592,718],[86,201,312,422,533,645],826,9,True)
row('goblin','run','goblin',690,851,[740,866,992,1106,1223,1333,1447],[807,926,1053,1168,1278,1382],826,12,True)
row('goblin','posture_break','goblin',900,1087,[20,201,347,489,676,871,1043,1246,1447],[108,265,407,578,775,951,1149,1354],1050,9)
row('goblin','horizontal_slash','goblin_combo',157,354,[0,213,412,604,930,1107,1270,1447],[86,281,488,679,977,1180,1361],335,11,scale=58/122)
row('goblin','upward_slash','goblin_combo',417,675,[0,210,409,601,928,1107,1270,1447],[93,290,485,687,977,1180,1360],649,11,scale=58/122)
row('goblin','downward_slam','goblin_combo',756,1021,[0,214,415,724,983,1257,1447],[111,318,520,822,1100,1367],999,10,scale=58/122)

enemy('goblin_dog',40,86,[48,36])
row('goblin_dog','idle','goblin_dog',128,264,[0,124,242,356,478,597,729],[64,179,292,414,529,649],243,6,True)
row('goblin_dog','walk','goblin_dog',128,264,[735,849,965,1080,1195,1311,1448],[790,904,1020,1138,1251,1370],243,9,True)
row('goblin_dog','run','goblin_dog',317,456,[0,202,405,608,811,1019,1227,1448],[100,304,508,710,915,1116,1332],431,12,True)
row('goblin_dog','jump_attack','goblin_dog',469,702,[0,174,314,463,677,884,1075,1262,1448],[85,244,382,561,777,969,1172,1360],[675,657,600,573,575,587,672,675],10)
row('goblin_dog','bite','goblin_dog',728,878,[0,191,366,551,742,925,1087,1247,1448],[105,277,454,650,835,1003,1164,1336],856,11)
row('goblin_dog','posture_break','goblin_dog',899,1068,[0,214,414,624,831,1038,1246,1448],[100,304,513,718,922,1135,1354],1040,9)

enemy('goblin_sentinel',72,146,[34,68])
row('goblin_sentinel','idle','goblin_sentinel',112,332,[0,128,229,330,443],[76,175,278,380],310,6,True)
row('goblin_sentinel','walk','goblin_sentinel',112,332,[444,556,658,760,860,971],[510,610,711,816,918],310,9,True)
row('goblin_sentinel','run','goblin_sentinel',112,332,[975,1104,1225,1338,1447],[1047,1161,1271,1380],312,12,True)
enemies['goblin_sentinel']['animations']['run']['frames'][-1]=dict(source='sentinel_run_repaired',rect=[270,190,1030,825],pivot=[675,1000],scale=72/654)
row('goblin_sentinel','thrust','goblin_sentinel',352,569,[0,200,433,794,1074,1268,1447],[105,313,535,872,1168,1346],548,11)
row('goblin_sentinel','combo','goblin_sentinel',582,803,[0,175,415,571,718,921,1135,1297,1447],[98,257,478,658,814,1006,1190,1370],783,11)
row('goblin_sentinel','posture_break','goblin_sentinel',819,1041,[0,245,492,737,982,1230,1447],[128,354,602,841,1089,1322],1017,9)

enemy('kobold_archer',68,135,[32,65])
row('kobold_archer','idle','kobold_archer',170,377,[0,120,230,339,448],[70,174,282,390],356,6,True)
row('kobold_archer','walk','kobold_archer',170,377,[451,558,663,766,868,975],[508,614,719,818,921],356,9,True)
row('kobold_archer','run','kobold_archer',170,377,[978,1094,1213,1327,1448],[1040,1154,1271,1386],356,12,True)
row('kobold_archer','shoot','kobold_archer',455,697,[0,156,339,531,710,902,1090,1276,1448],[82,256,438,625,805,1000,1173,1350],675,9)
# Storyboard panel 6 is a flying arrow, not a body pose. Keep it as an effect.
arrow=enemies['kobold_archer']['animations']['shoot']['frames'].pop(5)
enemies['kobold_archer']['effects']={'arrow':dict(source='kobold_archer',rect=[905,539,189,67])}
row('kobold_archer','posture_break','kobold_archer',777,1004,[0,243,486,729,968,1214,1448],[115,355,598,835,1072,1311],984,9)

enemy('kobold_clubber',86,149,[42,82])
row('kobold_clubber','idle','kobold_clubber',110,345,[0,114,213,315,419],[63,160,262,364],323,6,True)
row('kobold_clubber','walk','kobold_clubber',110,345,[420,553,682,813,950],[490,620,748,881],323,9,True)
row('kobold_clubber','run','kobold_clubber',110,345,[951,1114,1277,1448],[1034,1194,1360],323,12,True)
row('kobold_clubber','slam','kobold_clubber',372,625,[0,200,402,587,998,1269,1448],[105,302,499,711,1110,1340],597,10)
row('kobold_clubber','combo','kobold_clubber',651,863,[0,179,516,688,861,1098,1269,1448],[84,320,593,764,948,1178,1350],840,11)
row('kobold_clubber','posture_break','kobold_clubber',888,1086,[0,205,413,619,827,1039,1247,1448],[90,297,506,714,924,1135,1342],1062,9)

enemy('kobold_summoner',74,132,[34,70])
row('kobold_summoner','idle','kobold_summoner',147,384,[0,124,231,343,461],[75,183,293,407],359,6,True)
row('kobold_summoner','walk','kobold_summoner',147,384,[464,590,716,842,972],[525,650,778,903],359,9,True)
row('kobold_summoner','run','kobold_summoner',147,384,[975,1132,1288,1448],[1048,1205,1365],359,12,True)
row('kobold_summoner','summon','kobold_summoner',432,754,[0,173,331,510,697,884,1104,1258,1448],[89,241,429,609,783,970,1166,1335],730,9)
row('kobold_summoner','posture_break','kobold_summoner',815,1044,[0,208,416,620,825,1033,1240,1448],[92,298,505,713,918,1126,1335],1023,9)

# Reconstructed complete movement cutouts from the densely overlapping Clubber
# row. Measured delivered layout differs from the requested image grid.
for anim,top,bottom,centers,feet in [
    ('idle',0,374,[170,532,892,1260],357),
    ('walk',374,753,[164,533,905,1243],729),
    ('run',753,1086,[204,566,910],1058),
]:
    e=enemies['kobold_clubber']['animations'][anim]
    e['frames']=[dict(source='clubber_movement_repaired',rect=[i*362,top,362,bottom-top],pivot=[x,feet],scale=86/228) for i,x in enumerate(centers)]

# Group crowded rows so native assembly can follow connected silhouettes instead
# of cutting a spear, bow, staff or cape at an arbitrary vertical cell boundary.
groups={}
for e in enemies.values():
    for anim_name,a in e['animations'].items():
        for frame_index,frame in enumerate(a['frames']):
            if frame['source']=='clubber_movement_repaired': continue
            key=(frame['source'],frame['rect'][1],frame['rect'][3])
            groups.setdefault(key,[]).append(frame)
            if anim_name=='jump_attack': frame['register_body_feet']=True
            if anim_name=='jump_attack' and frame_index in [2,3,4,5]: frame['body_only']=True
for key,frames in groups.items():
    if len(frames)<2: continue
    seeds=[f['pivot'] for f in frames]
    if key[0]=='goblin_sentinel' and key[1]==112:
        # Reserve the discarded clipped last run pose so no neighbor consumes it.
        seeds=seeds+[[1380,312]]
    if key[0]=='kobold_archer' and key[1]==455:
        seeds=seeds+[[1000,626]]  # detached arrow is exported separately
    for index,frame in enumerate(frames):
        frame['owners']=seeds
        frame['owner']=index
        frame['rect']=[0,key[1],1447 if key[0] in ['goblin','goblin_combo','goblin_sentinel'] else 1448,key[2]]
Path('design/references/enemies/enemy-source-crops.json').write_text(json.dumps(enemies,indent=2)+'\n',encoding='utf-8')
print('Measured crop catalog:',sum(len(a['frames']) for e in enemies.values() for a in e['animations'].values()),'frames')
for name in enemies:
    width,height=enemies[name]['collider']
    Path('scenes/enemies/'+name+'.tscn').write_text(f'''[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/enemies/reference_enemy.gd" id="1"]
[ext_resource type="SpriteFrames" path="res://assets/characters/enemies/{name}.tres" id="2"]

[sub_resource type="RectangleShape2D" id="Body"]
size = Vector2({width}, {height})

[node name="{name}" type="CharacterBody2D"]
collision_layer = 2
collision_mask = 1
script = ExtResource("1")
enemy_kind = "{name}"

[node name="Visual" type="Node2D" parent="."]

[node name="Sprite" type="AnimatedSprite2D" parent="Visual"]
texture_filter = 1
position = Vector2(-128, -224)
sprite_frames = ExtResource("2")
animation = &"idle"
centered = false

[node name="Collision" type="CollisionShape2D" parent="."]
position = Vector2(0, {-height/2})
shape = SubResource("Body")
''',encoding='utf-8')
