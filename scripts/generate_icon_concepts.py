"""
beadot Icon Concepts - アイロンビーズ感を出す
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math, os

OUTPUT = '/home/claude/beadot/icon_concepts'
os.makedirs(OUTPUT, exist_ok=True)
SIZE = 1024
CENTER = SIZE // 2


def get_font(size):
    for p in ['/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
              '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf']:
        if os.path.exists(p):
            try: return ImageFont.truetype(p, size)
            except: pass
    return ImageFont.load_default()


def draw_bead(draw, cx, cy, radius, color, hole_ratio=0.28):
    """Draw a single fuse bead with center hole and subtle 3D effect"""
    r = radius
    hr = r * hole_ratio

    # Outer shadow
    draw.ellipse([cx-r+3, cy-r+4, cx+r+3, cy+r+4], fill='#00000020')

    # Main bead body
    draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=color)

    # Subtle rim (darker ring at edge)
    for i in range(3):
        rim_r = r - i
        draw.ellipse([cx-rim_r, cy-rim_r, cx+rim_r, cy+rim_r], outline=color + '80', width=1)

    # Inner gradient - lighter upper area
    highlight_r = r * 0.75
    hx = cx - r * 0.15
    hy = cy - r * 0.2
    # Simple highlight circle
    draw.ellipse([hx-highlight_r*0.5, hy-highlight_r*0.5, 
                  hx+highlight_r*0.5, hy+highlight_r*0.5], fill='#FFFFFF18')

    # Center hole (dark)
    draw.ellipse([cx-hr, cy-hr, cx+hr, cy+hr], fill='#1A1A1A')
    # Hole inner highlight
    draw.ellipse([cx-hr*0.7, cy-hr*0.7, cx+hr*0.65, cy+hr*0.65], fill='#2A2A2A')


def draw_plate_dot(draw, cx, cy, radius):
    """Draw a pegboard dot (empty peg)"""
    r = radius * 0.15
    draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill='#D8D8D8')


# ============================================================
# CONCEPT A: ハートの図案（アイロンビーズでハートマーク）
# ============================================================
def concept_a():
    img = Image.new('RGBA', (SIZE, SIZE), '#FFFEF8')
    draw = ImageDraw.Draw(img)

    # Warm cream background with subtle rounded rect
    margin = 60
    draw.rounded_rectangle([margin, margin, SIZE-margin, SIZE-margin], 
                           radius=180, fill='#FFFEF8')

    # Grid setup - 9x9 grid
    grid = 9
    cell = (SIZE - 240) / grid
    bead_r = cell * 0.42
    start_x = 120 + cell / 2
    start_y = 100 + cell / 2

    # Heart pattern in grid (1 = filled, 0 = empty peg)
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

    # Heart colors - warm gradient
    heart_colors = [
        '#FF6B6B', '#FF5252', '#FF4444', '#FF3D3D',
        '#FF5252', '#FF4444', '#FF3D3D', '#FF2D2D',
        '#FF4444', '#FF3D3D', '#EE3333', '#DD2222',
        '#FF3D3D', '#EE3333', '#DD2222', '#CC1111',
        '#EE3333', '#DD2222', '#CC1111',
        '#DD2222', '#CC1111',
        '#CC1111',
    ]
    ci = 0

    for row in range(grid):
        for col in range(grid):
            cx = start_x + col * cell
            cy = start_y + row * cell
            if heart[row][col]:
                c = heart_colors[ci % len(heart_colors)]
                ci += 1
                draw_bead(draw, cx, cy, bead_r, c)
            else:
                draw_plate_dot(draw, cx, cy, bead_r)

    # "beadot" text
    font = get_font(52)
    bbox = draw.textbbox((0,0), 'beadot', font=font)
    tw = bbox[2] - bbox[0]
    draw.text(((SIZE-tw)/2, SIZE - 130), 'beadot', fill='#333333', font=font)

    img.save(f'{OUTPUT}/concept_a_heart.png')
    return img


# ============================================================
# CONCEPT B: カラフルグリッド（プレート上のビーズ群）
# ============================================================
def concept_b():
    img = Image.new('RGBA', (SIZE, SIZE), '#F5F0E8')
    draw = ImageDraw.Draw(img)

    # Pegboard background - slightly warm beige
    board_margin = 80
    draw.rounded_rectangle([board_margin, board_margin, SIZE-board_margin, SIZE-board_margin],
                           radius=100, fill='#F0EBE0', outline='#E0D8C8', width=3)

    # 7x7 grid with colorful beads
    grid = 7
    cell = (SIZE - 240) / grid
    bead_r = cell * 0.44
    start_x = 120 + cell / 2
    start_y = 120 + cell / 2

    # Rainbow-ish pattern (abstract cute shape)
    colors = [
        ['#F8F8F0','#F8F8F0','#FFD93D','#FFD93D','#FFD93D','#F8F8F0','#F8F8F0'],
        ['#F8F8F0','#FF6B6B','#FFD93D','#FFD93D','#FFD93D','#6BCB77','#F8F8F0'],
        ['#FF6B6B','#FF6B6B','#FF9F43','#FF9F43','#6BCB77','#6BCB77','#4D96FF'],
        ['#FF6B6B','#FF9F43','#FF9F43','#FFD93D','#6BCB77','#4D96FF','#4D96FF'],
        ['#F8F8F0','#FF9F43','#FFD93D','#FFD93D','#4D96FF','#4D96FF','#F8F8F0'],
        ['#F8F8F0','#F8F8F0','#FFD93D','#6BCB77','#4D96FF','#F8F8F0','#F8F8F0'],
        ['#F8F8F0','#F8F8F0','#F8F8F0','#6BCB77','#F8F8F0','#F8F8F0','#F8F8F0'],
    ]

    for row in range(grid):
        for col in range(grid):
            cx = start_x + col * cell
            cy = start_y + row * cell
            c = colors[row][col]
            if c == '#F8F8F0':
                # Empty peg
                draw_plate_dot(draw, cx, cy, bead_r)
            else:
                draw_bead(draw, cx, cy, bead_r, c)

    img.save(f'{OUTPUT}/concept_b_rainbow.png')
    return img


# ============================================================
# CONCEPT C: 大きなビーズ1粒フォーカス + 背景にミニグリッド
# ============================================================
def concept_c():
    img = Image.new('RGBA', (SIZE, SIZE), '#FFFFFF')
    draw = ImageDraw.Draw(img)

    # Background: faint grid pattern
    grid = 12
    cell = SIZE / grid
    for row in range(grid):
        for col in range(grid):
            cx = col * cell + cell / 2
            cy = row * cell + cell / 2
            r = cell * 0.08
            draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill='#ECECEC')

    # Large center bead - vibrant coral/red
    big_r = 260
    draw_bead(draw, CENTER, CENTER - 30, big_r, '#FF5A5F', hole_ratio=0.25)

    # Extra shine on big bead
    shine_r = 60
    sx = CENTER - 80
    sy = CENTER - 110
    draw.ellipse([sx-shine_r, sy-shine_r, sx+shine_r, sy+shine_r], fill='#FFFFFF30')

    # "beadot" below
    font = get_font(64)
    bbox = draw.textbbox((0,0), 'beadot', font=font)
    tw = bbox[2] - bbox[0]
    draw.text(((SIZE-tw)/2, SIZE - 160), 'beadot', fill='#333333', font=font)

    img.save(f'{OUTPUT}/concept_c_single.png')
    return img


# ============================================================
# CONCEPT D: "b" をビーズで構成
# ============================================================
def concept_d():
    img = Image.new('RGBA', (SIZE, SIZE), '#FFFFFF')
    draw = ImageDraw.Draw(img)

    # 8x10 grid for letter "b"
    grid_c, grid_r = 8, 10
    cell = 88
    bead_r = cell * 0.44
    start_x = (SIZE - grid_c * cell) / 2 + cell / 2
    start_y = (SIZE - grid_r * cell) / 2 + cell / 2 - 20

    # "b" letter pattern
    b_pattern = [
        [1,0,0,0,0,0,0,0],
        [1,0,0,0,0,0,0,0],
        [1,0,0,0,0,0,0,0],
        [1,0,1,1,1,0,0,0],
        [1,1,0,0,0,1,0,0],
        [1,0,0,0,0,0,1,0],
        [1,0,0,0,0,0,1,0],
        [1,1,0,0,0,1,0,0],
        [1,0,1,1,1,0,0,0],
        [0,0,0,0,0,0,0,0],
    ]

    # Color palette - varied but harmonious
    palette = ['#FF6B6B', '#FF9F43', '#FFD93D', '#6BCB77', '#4D96FF', '#9B59B6', '#1ABC9C', '#E91E63']
    pi = 0

    for row in range(grid_r):
        for col in range(grid_c):
            cx = start_x + col * cell
            cy = start_y + row * cell
            if b_pattern[row][col]:
                draw_bead(draw, cx, cy, bead_r, palette[pi % len(palette)])
                pi += 1
            else:
                draw_plate_dot(draw, cx, cy, bead_r)

    img.save(f'{OUTPUT}/concept_d_letter_b.png')
    return img


# ============================================================
# CONCEPT E: プレート上の星（アイロンビーズプレート風）
# ============================================================
def concept_e():
    img = Image.new('RGBA', (SIZE, SIZE), '#FFF8F0')
    draw = ImageDraw.Draw(img)

    # Pegboard
    board_m = 60
    draw.rounded_rectangle([board_m, board_m, SIZE-board_m, SIZE-board_m],
                           radius=80, fill='#F5EFDF', outline='#DDD5C0', width=4)

    grid = 11
    cell = (SIZE - 180) / grid
    bead_r = cell * 0.43
    start_x = 90 + cell / 2
    start_y = 90 + cell / 2

    # Star pattern
    star = [
        [0,0,0,0,0,1,0,0,0,0,0],
        [0,0,0,0,1,1,1,0,0,0,0],
        [0,0,0,0,1,1,1,0,0,0,0],
        [1,1,1,1,1,1,1,1,1,1,1],
        [0,1,1,1,1,1,1,1,1,1,0],
        [0,0,1,1,1,1,1,1,1,0,0],
        [0,0,0,1,1,1,1,1,0,0,0],
        [0,0,1,1,1,1,1,1,1,0,0],
        [0,1,1,0,0,0,0,0,1,1,0],
        [1,1,0,0,0,0,0,0,0,1,1],
        [1,0,0,0,0,0,0,0,0,0,1],
    ]

    # Gold/amber star colors
    star_colors = ['#FFD700', '#FFC107', '#FFB300', '#FFA000', '#FF8F00', '#FFD93D', '#FFCA28']
    ci = 0

    for row in range(grid):
        for col in range(grid):
            cx = start_x + col * cell
            cy = start_y + row * cell
            if star[row][col]:
                draw_bead(draw, cx, cy, bead_r, star_colors[ci % len(star_colors)])
                ci += 1
            else:
                draw_plate_dot(draw, cx, cy, bead_r)

    img.save(f'{OUTPUT}/concept_e_star.png')
    return img


# ============================================================
# CONCEPT F: カメラ→ビーズ変換（半分写真/半分ビーズ）
# ============================================================
def concept_f():
    img = Image.new('RGBA', (SIZE, SIZE), '#FFFFFF')
    draw = ImageDraw.Draw(img)

    # Left half: smooth gradient (representing photo)
    for y in range(SIZE):
        for x in range(SIZE // 2):
            # Simple gradient
            r = int(255 - (y / SIZE) * 120 + (x / SIZE) * 60)
            g = int(180 - (y / SIZE) * 80 + (x / SIZE) * 100)
            b_val = int(120 + (y / SIZE) * 80)
            r = max(0, min(255, r))
            g = max(0, min(255, g))
            b_val = max(0, min(255, b_val))
            img.putpixel((x, y), (r, g, b_val, 255))

    # Right half: bead grid representation
    grid = 10
    cell = (SIZE // 2) / grid
    bead_r = cell * 0.42
    start_x = SIZE // 2 + cell / 2
    start_y = cell / 2

    # Colors that roughly match gradient
    right_colors = [
        ['#FFB4A2','#FFCDB2','#FFB4A2','#E5989B','#B5838D','#6D6875','#B5838D','#E5989B','#FFCDB2','#FFB4A2'],
        ['#FFCDB2','#FFB4A2','#E5989B','#B5838D','#6D6875','#6D6875','#B5838D','#E5989B','#FFB4A2','#FFCDB2'],
        ['#FFB4A2','#E5989B','#B5838D','#6D6875','#584B53','#584B53','#6D6875','#B5838D','#E5989B','#FFB4A2'],
        ['#E5989B','#B5838D','#6D6875','#584B53','#463940','#463940','#584B53','#6D6875','#B5838D','#E5989B'],
        ['#B5838D','#6D6875','#584B53','#463940','#3D3442','#3D3442','#463940','#584B53','#6D6875','#B5838D'],
        ['#6D6875','#584B53','#463940','#3D3442','#352F3B','#352F3B','#3D3442','#463940','#584B53','#6D6875'],
        ['#8B7D82','#7D6E73','#6D6069','#5D5260','#524957','#524957','#5D5260','#6D6069','#7D6E73','#8B7D82'],
        ['#9D8E8F','#8D7F84','#7D7079','#6D636E','#5D5664','#5D5664','#6D636E','#7D7079','#8D7F84','#9D8E8F'],
        ['#AE9F9A','#9E9090','#8E8186','#7E747C','#6E6772','#6E6772','#7E747C','#8E8186','#9E9090','#AE9F9A'],
        ['#BFB0A5','#AFA1A1','#9F9297','#8F858D','#7F7883','#7F7883','#8F858D','#9F9297','#AFA1A1','#BFB0A5'],
    ]

    for row in range(grid):
        for col in range(grid):
            cx = start_x + col * cell
            cy = start_y + row * cell
            draw_bead(draw, cx, cy, bead_r, right_colors[row][col], hole_ratio=0.22)

    # Divider line with arrow
    draw.line([(SIZE//2, 80), (SIZE//2, SIZE-80)], fill='#CCCCCC', width=2)
    # Arrow
    arrow_y = SIZE // 2
    draw.polygon([(SIZE//2 + 15, arrow_y - 12), (SIZE//2 + 15, arrow_y + 12), (SIZE//2 + 35, arrow_y)], fill='#888888')

    img.save(f'{OUTPUT}/concept_f_convert.png')
    return img


if __name__ == '__main__':
    print("Generating concept A: Heart pattern...")
    concept_a()
    print("Generating concept B: Rainbow grid...")
    concept_b()
    print("Generating concept C: Single big bead...")
    concept_c()
    print("Generating concept D: Letter 'b'...")
    concept_d()
    print("Generating concept E: Star pattern...")
    concept_e()
    print("Generating concept F: Photo→Bead conversion...")
    concept_f()
    print(f"\nDone! All concepts in {OUTPUT}/")
