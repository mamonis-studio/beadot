"""
beadot App Store Screenshot Generator
Generates 30 screenshots: 3 languages x 2 devices x 5 screens
iPhone 6.5" (1242x2688) + iPad 13" M4 (2064x2752)
"""
from PIL import Image, ImageDraw, ImageFont
import os

# Device specs
DEVICES = {
    'iphone': {'w': 1242, 'h': 2688, 'name': 'iPhone 6.5"'},
    'ipad': {'w': 2064, 'h': 2752, 'name': 'iPad 13"'},
}

LANGS = {
    'ja': {
        'screens': [
            {'title': '写真を撮るだけ', 'sub': 'アイロンビーズの図案を自動生成', 'mock': 'camera'},
            {'title': '3ブランド対応', 'sub': 'パーラー・ナノ・ハマビーズ', 'mock': 'settings'},
            {'title': '高精度な色変換', 'sub': 'CIEDE2000色差式で最適な色を選択', 'mock': 'pattern'},
            {'title': '買い物リスト', 'sub': '必要な色と個数を自動集計', 'mock': 'shopping'},
            {'title': 'PDF出力', 'sub': '実寸印刷してすぐ使える', 'mock': 'pdf'},
        ]
    },
    'en': {
        'screens': [
            {'title': 'Just Take a Photo', 'sub': 'Auto-generate bead patterns instantly', 'mock': 'camera'},
            {'title': '3 Bead Brands', 'sub': 'Perler, Nano, and Hama Beads', 'mock': 'settings'},
            {'title': 'Precise Colors', 'sub': 'CIEDE2000 formula picks the closest match', 'mock': 'pattern'},
            {'title': 'Shopping List', 'sub': 'Auto-calculated bead counts by color', 'mock': 'shopping'},
            {'title': 'PDF Export', 'sub': 'Actual-size print, ready to use', 'mock': 'pdf'},
        ]
    },
    'zh': {
        'screens': [
            {'title': '拍张照片就行', 'sub': '自动生成拼豆图案', 'mock': 'camera'},
            {'title': '三大品牌', 'sub': 'Perler、Nano、Hama拼豆', 'mock': 'settings'},
            {'title': '精准配色', 'sub': 'CIEDE2000色差公式选择最接近的颜色', 'mock': 'pattern'},
            {'title': '购物清单', 'sub': '自动统计所需颜色和数量', 'mock': 'shopping'},
            {'title': 'PDF导出', 'sub': '实际尺寸打印，即用', 'mock': 'pdf'},
        ]
    },
}

# Bead colors for mock UI
BEAD_PALETTE = [
    '#E74C3C', '#F39C12', '#F1C40F', '#27AE60', '#3498DB',
    '#9B59B6', '#1ABC9C', '#E91E63', '#FF5722', '#795548',
    '#607D8B', '#2196F3', '#4CAF50', '#CDDC39', '#FF9800',
]


def get_font(size, bold=False):
    paths = [
        '/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc',
        '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',
        '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
        '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
    ]
    if bold:
        paths.insert(0, '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf')
    for p in paths:
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, size)
            except:
                continue
    return ImageFont.load_default()


def draw_bead_grid(draw, x, y, w, h, cols=8, rows=8):
    """Draw a mock bead pattern grid"""
    cell_w = w / cols
    cell_h = h / rows
    cell = min(cell_w, cell_h)
    start_x = x + (w - cell * cols) / 2
    start_y = y + (h - cell * rows) / 2
    bead_r = cell * 0.42

    for r in range(rows):
        for c in range(cols):
            cx = start_x + c * cell + cell / 2
            cy = start_y + r * cell + cell / 2
            color = BEAD_PALETTE[(r * cols + c) % len(BEAD_PALETTE)]
            # Shadow
            draw.ellipse([cx - bead_r + 1, cy - bead_r + 2, cx + bead_r + 1, cy + bead_r + 2], fill='#E0E0E0')
            # Bead
            draw.ellipse([cx - bead_r, cy - bead_r, cx + bead_r, cy + bead_r], fill=color)


def draw_mock_camera(draw, W, H, phone_top, phone_h):
    """Draw camera screen mock"""
    # Dark background for camera
    draw.rectangle([W * 0.08, phone_top, W * 0.92, phone_top + phone_h], fill='#1A1A1A', outline='#333', width=3)
    # Viewfinder area
    vf_y = phone_top + phone_h * 0.1
    vf_h = phone_h * 0.65
    draw.rectangle([W * 0.12, vf_y, W * 0.88, vf_y + vf_h], fill='#2A2A2A')
    # Sample "photo" - colorful gradient
    for i in range(20):
        c = ['#E74C3C', '#F39C12', '#27AE60', '#3498DB', '#9B59B6'][i % 5]
        stripe_y = vf_y + i * (vf_h / 20)
        draw.rectangle([W * 0.12, stripe_y, W * 0.88, stripe_y + vf_h / 20], fill=c + '40')
    # Capture button
    btn_y = phone_top + phone_h * 0.82
    btn_r = phone_h * 0.05
    draw.ellipse([W / 2 - btn_r, btn_y - btn_r, W / 2 + btn_r, btn_y + btn_r], fill='#FFFFFF', outline='#333', width=3)


def draw_mock_settings(draw, W, H, phone_top, phone_h):
    """Draw settings screen mock"""
    draw.rectangle([W * 0.08, phone_top, W * 0.92, phone_top + phone_h], fill='#FFFFFF', outline='#E0E0E0', width=3)
    # Title bar
    font_sm = get_font(int(W * 0.025))
    draw.text((W * 0.12, phone_top + phone_h * 0.04), 'SELECT SETTINGS', fill='#111', font=font_sm)
    # Brand selector mock
    y = phone_top + phone_h * 0.12
    brands = ['PERLER', 'NANO', 'HAMA']
    seg_w = (W * 0.8) / 3
    for i, b in enumerate(brands):
        x1 = W * 0.1 + i * seg_w
        fill = '#111111' if i == 0 else '#FFFFFF'
        tc = '#FFFFFF' if i == 0 else '#111111'
        draw.rectangle([x1, y, x1 + seg_w, y + phone_h * 0.05], fill=fill, outline='#111')
        draw.text((x1 + seg_w * 0.25, y + phone_h * 0.012), b, fill=tc, font=get_font(int(W * 0.02)))
    # Shape selector mock
    y += phone_h * 0.1
    shapes = ['\u25A0', '\u2B22', '\u25CF', '\u2665', '\u2605']
    for i, s in enumerate(shapes):
        sx = W * 0.15 + i * (W * 0.15)
        fill = '#111111' if i == 0 else '#FFFFFF'
        tc = '#FFFFFF' if i == 0 else '#111111'
        draw.rectangle([sx, y, sx + W * 0.1, y + W * 0.1], fill=fill, outline='#111', width=2)
    # Size buttons
    y += phone_h * 0.15
    for i, label in enumerate(['S - 15x15', 'L - 29x29', '2L - 29x58', '4L - 58x58']):
        by = y + i * phone_h * 0.06
        fill = '#111111' if i == 0 else '#FFFFFF'
        tc = '#FFFFFF' if i == 0 else '#111111'
        draw.rounded_rectangle([W * 0.1, by, W * 0.9, by + phone_h * 0.045], radius=10, fill=fill, outline='#111', width=2)
        draw.text((W * 0.35, by + phone_h * 0.01), label, fill=tc, font=get_font(int(W * 0.025)))


def draw_mock_pattern(draw, W, H, phone_top, phone_h):
    """Draw pattern screen mock"""
    draw.rectangle([W * 0.08, phone_top, W * 0.92, phone_top + phone_h], fill='#FFFFFF', outline='#E0E0E0', width=3)
    # Mode selector
    y = phone_top + phone_h * 0.04
    modes = ['COLOR', 'SYMBOL', 'NUMBER']
    seg_w = (W * 0.7) / 3
    for i, m in enumerate(modes):
        x1 = W * 0.15 + i * seg_w
        fill = '#111111' if i == 0 else '#FFFFFF'
        tc = '#FFFFFF' if i == 0 else '#111111'
        draw.rectangle([x1, y, x1 + seg_w, y + phone_h * 0.04], fill=fill, outline='#111')
        draw.text((x1 + seg_w * 0.2, y + phone_h * 0.008), m, fill=tc, font=get_font(int(W * 0.018)))
    # Bead grid
    grid_y = phone_top + phone_h * 0.12
    draw_bead_grid(draw, W * 0.1, grid_y, W * 0.8, phone_h * 0.6, cols=10, rows=10)
    # Palette bar at bottom
    pal_y = phone_top + phone_h * 0.78
    for i in range(8):
        cx = W * 0.12 + i * W * 0.1
        r = W * 0.035
        draw.ellipse([cx - r, pal_y - r, cx + r, pal_y + r], fill=BEAD_PALETTE[i], outline='#E0E0E0', width=1)


def draw_mock_shopping(draw, W, H, phone_top, phone_h):
    """Draw shopping list mock"""
    draw.rectangle([W * 0.08, phone_top, W * 0.92, phone_top + phone_h], fill='#FFFFFF', outline='#E0E0E0', width=3)
    font_sm = get_font(int(W * 0.022))
    font_xs = get_font(int(W * 0.018))
    # Header
    draw.text((W * 0.12, phone_top + phone_h * 0.04), 'SHOPPING LIST', fill='#111', font=font_sm)
    # Items
    items = [
        ('#E74C3C', 'Red', '42'), ('#3498DB', 'Blue', '38'), ('#27AE60', 'Green', '35'),
        ('#F1C40F', 'Yellow', '28'), ('#9B59B6', 'Purple', '24'), ('#FF5722', 'Orange', '21'),
        ('#1ABC9C', 'Teal', '18'), ('#E91E63', 'Pink', '15'),
    ]
    for i, (color, name, count) in enumerate(items):
        iy = phone_top + phone_h * 0.1 + i * phone_h * 0.065
        # Checkbox
        if i < 3:
            draw.rectangle([W * 0.12, iy + 4, W * 0.12 + 20, iy + 24], fill='#111', outline='#111', width=2)
            draw.text((W * 0.12 + 3, iy + 2), '\u2713', fill='#FFF', font=font_xs)
        else:
            draw.rectangle([W * 0.12, iy + 4, W * 0.12 + 20, iy + 24], fill='#FFF', outline='#CCC', width=2)
        # Color circle
        r = 12
        draw.ellipse([W * 0.18 - r, iy + 5, W * 0.18 + r, iy + 5 + 2 * r], fill=color)
        # Name
        draw.text((W * 0.24, iy + 4), name, fill='#111', font=font_sm)
        # Count
        draw.text((W * 0.82, iy + 4), count, fill='#111', font=font_sm)


def draw_mock_pdf(draw, W, H, phone_top, phone_h):
    """Draw PDF export mock"""
    draw.rectangle([W * 0.08, phone_top, W * 0.92, phone_top + phone_h], fill='#F5F5F5', outline='#E0E0E0', width=3)
    # Paper
    paper_x = W * 0.15
    paper_y = phone_top + phone_h * 0.08
    paper_w = W * 0.7
    paper_h = phone_h * 0.7
    draw.rectangle([paper_x, paper_y, paper_x + paper_w, paper_y + paper_h], fill='#FFFFFF', outline='#DDD', width=2)
    # Shadow
    draw.rectangle([paper_x + 3, paper_y + 3, paper_x + paper_w + 3, paper_y + paper_h + 3], fill='#E8E8E8')
    draw.rectangle([paper_x, paper_y, paper_x + paper_w, paper_y + paper_h], fill='#FFFFFF', outline='#DDD', width=1)
    # Header text
    font_sm = get_font(int(W * 0.02))
    draw.text((paper_x + 16, paper_y + 12), 'beadot', fill='#111', font=get_font(int(W * 0.025), bold=True))
    draw.text((paper_x + 16, paper_y + 36), 'Perler / Square S / 15x15', fill='#888', font=font_sm)
    # Mini grid on PDF
    draw_bead_grid(draw, paper_x + paper_w * 0.1, paper_y + paper_h * 0.12, paper_w * 0.8, paper_h * 0.5, cols=8, rows=8)


def generate_screenshot(lang, screen_idx, device_key):
    device = DEVICES[device_key]
    W, H = device['w'], device['h']
    screen = LANGS[lang]['screens'][screen_idx]

    img = Image.new('RGB', (W, H), '#FFFFFF')
    draw = ImageDraw.Draw(img)

    # Title area
    title_font = get_font(int(W * 0.065), bold=True)
    sub_font = get_font(int(W * 0.032))

    title = screen['title']
    sub = screen['sub']

    # Center title
    bbox = draw.textbbox((0, 0), title, font=title_font)
    tw = bbox[2] - bbox[0]
    draw.text(((W - tw) / 2, H * 0.06), title, fill='#111111', font=title_font)

    # Subtitle
    bbox2 = draw.textbbox((0, 0), sub, font=sub_font)
    sw = bbox2[2] - bbox2[0]
    draw.text(((W - sw) / 2, H * 0.11), sub, fill='#888888', font=sub_font)

    # Phone mockup area
    phone_top = H * 0.17
    phone_h = H * 0.75

    mock_fn = {
        'camera': draw_mock_camera,
        'settings': draw_mock_settings,
        'pattern': draw_mock_pattern,
        'shopping': draw_mock_shopping,
        'pdf': draw_mock_pdf,
    }

    mock_fn[screen['mock']](draw, W, H, phone_top, phone_h)

    return img


def main():
    base_dir = '/home/claude/beadot/fastlane/screenshots'

    lang_dirs = {'ja': 'ja', 'en': 'en-US', 'zh': 'zh-Hans'}

    total = 0
    for lang, dir_name in lang_dirs.items():
        for device_key in ['iphone', 'ipad']:
            for idx in range(5):
                img = generate_screenshot(lang, idx, device_key)
                
                device = DEVICES[device_key]
                suffix = f'{device["w"]}x{device["h"]}'
                filename = f'{idx + 1:02d}_{LANGS[lang]["screens"][idx]["mock"]}_{suffix}.png'
                
                out_dir = os.path.join(base_dir, dir_name)
                os.makedirs(out_dir, exist_ok=True)
                out_path = os.path.join(out_dir, filename)
                img.save(out_path, 'PNG')
                total += 1
                print(f'  {dir_name}/{filename}')

    print(f'\nDone! Generated {total} screenshots')


if __name__ == '__main__':
    main()
