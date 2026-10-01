"""Inspect delivered extraction alpha and source extents without modifying images."""
from pathlib import Path
from PIL import Image
import numpy as np
from collections import deque

for path in sorted(Path("design/references/enemies/extracted").glob("*.png")):
    image = Image.open(path).convert("RGBA")
    alpha = image.getchannel("A")
    print(path.stem, image.size, "alpha", alpha.getextrema(),
          "right edge", alpha.crop((image.width - 1, 0, image.width, image.height)).getextrema())
    if path.stem in ['kobold_clubber','goblin_sentinel']:
        a=np.asarray(alpha)[100:340]>100
        visited=np.zeros(a.shape,dtype=bool)
        for y,x in zip(*np.nonzero(a)):
            if visited[y,x]: continue
            pending=deque([(x,y)])
            visited[y,x]=True
            area=0; minx=maxx=x; miny=maxy=y
            while pending:
                px,py=pending.popleft(); area+=1
                minx=min(minx,px); maxx=max(maxx,px); miny=min(miny,py); maxy=max(maxy,py)
                for nx,ny in [(px-1,py),(px+1,py),(px,py-1),(px,py+1)]:
                    if 0<=nx<a.shape[1] and 0<=ny<a.shape[0] and a[ny,nx] and not visited[ny,nx]:
                        visited[ny,nx]=True; pending.append((nx,ny))
            if area>500: print(' component',area,[minx,miny+100,maxx+1,maxy+101])
