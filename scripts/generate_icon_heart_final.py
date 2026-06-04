"""beadot Icon - Heart, clean flat beads, NO holes"""
from PIL import Image, ImageDraw, ImageFont
import os

OUTPUT = '/home/claude/beadot/icon_final'
os.makedirs(OUTPUT, exist_ok=True)
SIZE = 1024

def get_font(size):
    for p in ['/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
              '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf']:
        if os.path.exists(p):
            try: return ImageFont.truetype(p, size)
            except: pass
    return ImageFont.load_default()

def draw_bead(draw, cx, cy, radius, color):
    r = radius
    # Soft shadow
    draw.ellipse([cx-r+2, cy-r+3, cx+r+2, cy+r+3], fill='#D0C8C0')
    # Solid circle
    draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=color)
    # Tiny highlight dot
    dr = r * 0.11
    dx, dy = cx - r*0.28, cy - r*0.28
    draw.ellipse([dx-dr, dy-dr, dx+dr, dy+dr], fill='#FFFFFF50')

def draw_peg(draw, cx, cy, radius):
    r = radius * 0.12
    draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill='#D0D0D0')

def generate():
    img = Image.new('RGBA', (SIZE, SIZE), '#FFF9F5')
    draw = ImageDraw.Draw(img)
    grid = 9
    cell = (SIZE - 200) / grid
    bead_r = cell * 0.43
    sx, sy = 100 + cell/2, 70 + cell/2

    heart = [
        [0,0,0,0,0,0,0,0,0],
        [0,0,1,1,0,1,1,0,0],
        [0,1,1,1,1,1,1,1,0],
        [0,1,1,1,1,1,1,1,0],
        [0,1,1,1,1,1,1,1,0],
        [0,0,1,1,1,1,1,0,0],
        [0,0,0,1,1,1,0,0,0],
        [0,0,0,0,1,0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
    ]
    colors = [
        [0,0,0,0,0,0,0,0,0],
        [0,0,'#FF8A80','#FF8A80',0,'#FF8A80','#FF8A80',0,0],
        [0,'#FF7E73','#FF7066','#FF6659','#FF5C4D','#FF6659','#FF7066','#FF7E73',0],
        [0,'#FF6F62','#FF5F52','#FF5244','#FF4838','#FF5244','#FF5F52','#FF6F62',0],
        [0,'#FF6055','#FF5044','#FF4336','#FF382B','#FF4336','#FF5044','#FF6055',0],
        [0,0,'#FF4838','#FF3B2E','#FF3025','#FF3B2E','#FF4838',0,0],
        [0,0,0,'#FF3025','#FF261C','#FF3025',0,0,0],
        [0,0,0,0,'#FF1E14',0,0,0,0],
        [0,0,0,0,0,0,0,0,0],
    ]
    for row in range(grid):
        for col in range(grid):
            cx, cy = sx + col*cell, sy + row*cell
            if heart[row][col]:
                draw_bead(draw, cx, cy, bead_r, colors[row][col])
            else:
                draw_peg(draw, cx, cy, bead_r)

    font = get_font(48)
    bbox = draw.textbbox((0,0), 'beadot', font=font)
    tw = bbox[2] - bbox[0]
    draw.text(((SIZE-tw)/2, SIZE-115), 'beadot', fill='#555555', font=font)
    return img

def gen_sizes(base, out):
    ios = {'Icon-App-20x20@1x.png':20,'Icon-App-20x20@2x.png':40,'Icon-App-20x20@3x.png':60,
        'Icon-App-29x29@1x.png':29,'Icon-App-29x29@2x.png':58,'Icon-App-29x29@3x.png':87,
        'Icon-App-40x40@1x.png':40,'Icon-App-40x40@2x.png':80,'Icon-App-40x40@3x.png':120,
        'Icon-App-60x60@2x.png':120,'Icon-App-60x60@3x.png':180,
        'Icon-App-76x76@1x.png':76,'Icon-App-76x76@2x.png':152,
        'Icon-App-83.5x83.5@2x.png':167,'Icon-App-1024x1024@1x.png':1024}
    andr = {'mipmap-mdpi/ic_launcher.png':48,'mipmap-hdpi/ic_launcher.png':72,
        'mipmap-xhdpi/ic_launcher.png':96,'mipmap-xxhdpi/ic_launcher.png':144,
        'mipmap-xxxhdpi/ic_launcher.png':192,'playstore-icon.png':512}
    d = os.path.join(out,'ios'); os.makedirs(d, exist_ok=True)
    for n,px in ios.items(): base.resize((px,px),Image.LANCZOS).save(os.path.join(d,n))
    for n,px in andr.items():
        p=os.path.join(out,'android',n); os.makedirs(os.path.dirname(p),exist_ok=True)
        base.resize((px,px),Image.LANCZOS).save(p)
        if 'playstore' not in n:
            rp=p.replace('ic_launcher','ic_launcher_round')
            os.makedirs(os.path.dirname(rp),exist_ok=True)
            r2=base.resize((px,px),Image.LANCZOS)
            m=Image.new('L',(px,px),0); ImageDraw.Draw(m).ellipse([0,0,px-1,px-1],fill=255)
            o=Image.new('RGBA',(px,px),(0,0,0,0)); o.paste(r2,mask=m); o.save(rp)

if __name__=='__main__':
    icon = generate()
    icon.save(f'{OUTPUT}/icon_1024.png')
    gen_sizes(icon, OUTPUT)
    print("Done!")
