"""Rasterize the project's geometric icon for native launchers (Pillow)."""
from pathlib import Path
import json,hashlib
from PIL import Image,ImageDraw
im=Image.new('RGB',(1024,1024),'#171124');d=ImageDraw.Draw(im)
d.ellipse((188,188,836,836),outline='#8b769c',width=6)
d.ellipse((240,240,784,784),outline='#695376',width=4)
d.polygon([(512,200),(566,456),(824,512),(566,568),(512,824),(458,568),(200,512),(458,456)],fill='#cab78a')
d.polygon([(512,440),(584,512),(512,584),(440,512)],fill='#171124')
for x,y in [(286,286),(738,738)]: d.ellipse((x-12,y-12,x+12,y+12),fill='#cab78a')
outputs=[]
def save(path,size):
 p=Path(path);p.parent.mkdir(parents=True,exist_ok=True);im.resize((size,size),Image.Resampling.LANCZOS).save(p);outputs.append({'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:save(f'android/app/src/main/res/mipmap-{density}/ic_launcher.png',size)
for size in [192,512]:
 save(f'web/icons/Icon-{size}.png',size);save(f'web/icons/Icon-maskable-{size}.png',size)
save('web/favicon.png',32)
save('assets/branding/app_icon.png',512)
for platform in ['ios','macos']:
 root=Path(f'{platform}/Runner/Assets.xcassets/AppIcon.appiconset')
 data=json.loads((root/'Contents.json').read_text())
 for item in data['images']:
  name=item.get('filename')
  if name:save(root/name,round(float(item['size'].split('x')[0])*float(item['scale'].rstrip('x'))))
p=Path('windows/runner/resources/app_icon.ico');im.save(p,format='ICO',sizes=[(16,16),(32,32),(48,48),(64,64),(128,128),(256,256)])
outputs.append({'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
Path('docs/evidence/icon-provenance.json').write_text(json.dumps({'source':'assets/branding/app_icon.svg and tool/generate_icons.py','author':'Original geometric artwork for Arcanum','license':'Project-owned original artwork, available for this app','date':'2026-09-14','transformation':'Procedural rendering at 1024px; Lanczos scaling for platform sizes','outputs':outputs},indent=2))
