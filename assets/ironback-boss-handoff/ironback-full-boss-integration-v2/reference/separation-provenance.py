from PIL import Image,ImageDraw,ImageOps
from pathlib import Path
import json
out=Path('outputs/ironback-full-handoff/sprites')
im=Image.open(out/'ironback-keypose-atlas.png').convert('RGBA')
rows=[
('idle_walk',['idle_01','idle_02','walk_01','walk_02','walk_03','walk_04'],(0,218),[(0,266),(270,521),(524,777),(780,1027),(1030,1283),(1286,1536)]),
('smash',['smash_crouch','smash_rise','smash_overhead','smash_downstroke','smash_impact','smash_recovery'],(219,433),[(0,267),(271,514),(540,766),(788,1006),(1031,1279),(1287,1536)]),
('leap',['leap_crouch','leap_takeoff','leap_airborne','leap_descend','leap_impact','leap_recovery'],(434,637),[(0,265),(272,537),(539,820),(824,1027),(1040,1277),(1287,1536)]),
('backhand_rush',['backhand_tell','backhand_active','backhand_recovery','rush_tell','rush_active','rush_brake'],(638,810),[(0,262),(280,581),(583,781),(785,1026),(1029,1281),(1288,1536)]),
('misc',['hurt','phase_change','defeat_kneel','defeat_final','impact_fx','shockwave_fx'],(811,1024),[(0,266),(275,521),(530,735),(742,1028),(1030,1275),(1280,1536)])]
manifest={'status':'registered key poses, not complete frame-by-frame animations','source_dimensions':list(im.size),'body_canvas':[384,448],'body_pivot':[192,340],'frames':[],'clips':{'idle':['idle_01','idle_02'],'knuckle_walk':['walk_01','walk_02','walk_03','walk_04'],'seismic_smash':['smash_crouch','smash_rise','smash_overhead','smash_downstroke','smash_impact','smash_recovery'],'faultline_barrage':'reuse seismic_smash keys with 3 guarded impact events','bounding_impact':['leap_crouch','leap_takeoff','leap_airborne','leap_descend','leap_impact','leap_recovery'],'hydraulic_backhand':['backhand_tell','backhand_active','backhand_recovery'],'piston_rush':['rush_tell','rush_active','rush_brake'],'hurt':['hurt'],'phase_change':['phase_change'],'defeat':['defeat_kneel','defeat_final'],'impact_core':['impact_fx'],'shockwave_travel':['shockwave_fx']}}
preview=Image.new('RGB',(6*384,5*480),(40,40,45));d=ImageDraw.Draw(preview)
for rowidx,(group,names,(y0,y1),xs) in enumerate(rows):
 for col,(name,(x0,x1)) in enumerate(zip(names,xs)):
  crop=im.crop((x0,y0,x1,y1))
  # Use strong opacity for bounds so a soft vent glow does not change the root.
  core=crop.getchannel('A').point(lambda a:255 if a>=160 else 0)
  box=core.getbbox(); assert box is not None,name
  bx0,by0,bx1,by1=box
  # Keep full alpha/glow within the measured pose region, do not chroma-key.
  canvas=Image.new('RGBA',(384,448),(0,0,0,0))
  dx=192-(bx0+bx1)//2;dy=340-by1
  assert dx>=0 and dy>=0 and dx+crop.width<=384 and dy+crop.height<=448,(name,dx,dy,crop.size)
  canvas.alpha_composite(crop,(dx,dy))
  canvas.save(out/(name+'.png'))
  entry={'name':name,'path':name+'.png','group':group,'source_rect':[x0,y0,x1-x0,y1-y0],'canvas':[384,448],'pivot':[192,340],'opaque_bounds':list(canvas.getchannel('A').point(lambda a:255 if a>=160 else 0).getbbox()),'registration':'estimated bottom-center of strong-alpha silhouette; verify root/foot placement in game'}
  manifest['frames'].append(entry)
  px=col*384;py=rowidx*480
  checker=Image.new('RGBA',(384,448),'#333940');cd=ImageDraw.Draw(checker)
  for yy in range(0,448,16):
   for xx in range(0,384,16):
    if (xx//16+yy//16)%2:cd.rectangle((xx,yy,xx+15,yy+15),fill='#4a535c')
  checker.alpha_composite(canvas);preview.paste(checker.convert('RGB'),(px,py));d.text((px+8,py+452),name,fill='white')
  # Confirm actual transparent pixels and image decode for each deliverable.
  assert canvas.getchannel('A').getextrema()[0]==0
(out/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
preview.save('work/ironback-separated-preview.jpg')
print('30 RGBA cutouts decoded, padded without rescaling; all contain alpha-zero background.')


