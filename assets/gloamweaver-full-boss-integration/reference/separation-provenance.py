from pathlib import Path
from PIL import Image,ImageDraw
import json
root=Path('outputs/gloamweaver-full-handoff')
body_names=[
['ceiling_idle_01','ceiling_idle_02','ceiling_crawl_01','ceiling_crawl_02','ceiling_crawl_03','ceiling_crawl_04'],
['swing_prepare','swing_hang','swing_rake','swing_rise','swing_recovery','reattach_catch'],
['zip_aim','zip_release','zip_compress','zip_travel','zip_arrival','zip_recovery'],
['trap_prepare','trap_release','trap_recovery','drop_gather','drop_airborne','drop_impact'],
['floor_idle','bite_tell','bite_active','hurt','phase_change','defeat']]
body_rows=[(0,198),(198,416),(416,610),(610,806),(806,1024)]
body_cols=[[(0,260),(260,511),(511,775),(775,1032),(1032,1282),(1282,1536)],
[(0,254),(254,491),(491,790),(790,1047),(1047,1287),(1287,1536)],
[(0,259),(259,519),(519,768),(768,1044),(1044,1284),(1284,1536)],
[(0,259),(259,519),(519,776),(776,1020),(1020,1258),(1258,1536)],
[(0,256),(256,510),(510,794),(794,1031),(1031,1253),(1253,1536)]]
fx_names=[['hook_head','anchor_rosette','cable_segment','swing_streak'],['trap_seed','trap_unfold','trap_active','trap_trigger'],['landing_dust','bite_streak','hit_fray','web_dissolve']]
fx_rows=[(0,354),(354,732),(732,1086)]
fx_cols=[[(0,382),(382,717),(717,1114),(1114,1448)],[(0,365),(365,681),(681,1121),(1121,1448)],[(0,414),(414,746),(746,1086),(1086,1448)]]

def separate(folder, source, names, rows, columns, size):
 im=Image.open(root/folder/source).convert('RGBA');cols=len(names[0]);count=len(names)*cols
 manifest={'status':'static key poses/effect keys, not complete animated frame sequences','source_size':list(im.size),'canvas':[size,size],'estimated_root':[size//2,size//2],'root_method':'center of alpha>=160 silhouette bounds, refine anatomical sockets/support in engine','frames':[]}
 preview=Image.new('RGB',(cols*size,len(names)*(size+28)),(26,28,34));pd=ImageDraw.Draw(preview)
 for row,(ys,xs,row_names) in enumerate(zip(rows,columns,names)):
  for col,(name,(x0,x1)) in enumerate(zip(row_names,xs)):
   y0,y1=ys; crop=im.crop((x0,y0,x1,y1))
   bounds=crop.getchannel('A').point(lambda a:255 if a>=160 else 0).getbbox();assert bounds,name
   bx0,by0,bx1,by1=bounds
   dx=size//2-(bx0+bx1)//2;dy=size//2-(by0+by1)//2
   assert dx>=0 and dy>=0 and dx+crop.width<=size and dy+crop.height<=size,(name,crop.size,dx,dy)
   frame=Image.new('RGBA',(size,size),(0,0,0,0));frame.alpha_composite(crop,(dx,dy));frame.save(root/folder/(name+'.png'))
   alpha=frame.getchannel('A'); assert alpha.getextrema()[0]==0
   core=alpha.point(lambda a:255 if a>=160 else 0); final_bounds=core.getbbox()
   manifest['frames'].append({'name':name,'path':name+'.png','source_rect':[x0,y0,x1-x0,y1-y0],'canvas':[size,size],'estimated_root':[size//2,size//2],'opaque_bounds':list(final_bounds),'alpha_zero_pixels':alpha.histogram()[0],'source_crop_preserved':True})
   checker=Image.new('RGBA',(size,size),'#313940');d=ImageDraw.Draw(checker)
   for yy in range(0,size,16):
    for xx in range(0,size,16):
     if (xx//16+yy//16)%2:d.rectangle((xx,yy,xx+15,yy+15),fill='#48535d')
   checker.alpha_composite(frame);px=col*size;py=row*(size+28);preview.paste(checker.convert('RGB'),(px,py));pd.text((px+6,py+size+4),name,fill='white')
 (root/folder/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
 preview.save(root/folder/'preview-checkerboard.jpg')
 print(folder,count,'PNG cutouts verified',im.size,'canvas',size)

separate('sprites','body-atlas-source.png',body_names,body_rows,body_cols,384)
separate('vfx','vfx-atlas-source.png',fx_names,fx_rows,fx_cols,640)

