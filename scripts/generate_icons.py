"""
beadot App Icon Generator
Generates 1024x1024 icon + all iOS/Android sizes
Design: Minimalist white background, 3x3 colored bead dots
"""
from PIL import Image, ImageDraw, ImageFont
import os, math

def generate_icon(size=1024):
    img = Image.new('RGB', (size, size), '#FFFFFF')
    draw = ImageDraw.Draw(img)
    
    # Subtle rounded rect background (white with very light border effect)
    # We'll draw the content directly on white
    
    # 3x3 grid of colored bead circles
    # Using distinctive bead colors for visual impact
    bead_colors = [
        '#E74C3C', '#F39C12', '#F1C40F',  # red, orange, yellow
        '#27AE60', '#3498DB', '#9B59B6',  # green, blue, purple
        '#1ABC9C', '#E91E63', '#FF5722',  # teal, pink, deep orange
    ]
    
    # Grid positioning
    grid_size = 3
    padding = size * 0.18  # outer padding
    grid_area = size - padding * 2
    cell_size = grid_area / grid_size
    bead_radius = cell_size * 0.38
    
    # Draw beads
    for row in range(grid_size):
        for col in range(grid_size):
            cx = padding + col * cell_size + cell_size / 2
            cy = padding + row * cell_size + cell_size / 2
            color = bead_colors[row * grid_size + col]
            
            # Shadow
            draw.ellipse(
                [cx - bead_radius + 2, cy - bead_radius + 3, 
                 cx + bead_radius + 2, cy + bead_radius + 3],
                fill='#E8E8E8'
            )
            # Bead circle
            draw.ellipse(
                [cx - bead_radius, cy - bead_radius, 
                 cx + bead_radius, cy + bead_radius],
                fill=color
            )
            # Highlight
            hl_r = bead_radius * 0.25
            hl_x = cx - bead_radius * 0.3
            hl_y = cy - bead_radius * 0.3
            draw.ellipse(
                [hl_x - hl_r, hl_y - hl_r, hl_x + hl_r, hl_y + hl_r],
                fill='#FFFFFF40'
            )
    
    # "beadot" text at bottom
    # Use a simple approach - draw small text
    text_y = size * 0.88
    font_size = int(size * 0.055)
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Light.ttf", font_size)
    except:
        font = ImageFont.load_default()
    
    text = "beadot"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    draw.text((size / 2 - text_w / 2, text_y), text, fill='#333333', font=font)
    
    return img

def generate_all_sizes(base_img, output_dir):
    """Generate all required icon sizes for iOS and Android"""
    os.makedirs(output_dir, exist_ok=True)
    
    # iOS sizes (filename: Icon-App-{w}x{h}@{scale}x.png)
    ios_sizes = {
        'Icon-App-20x20@1x.png': 20,
        'Icon-App-20x20@2x.png': 40,
        'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29,
        'Icon-App-29x29@2x.png': 58,
        'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40,
        'Icon-App-40x40@2x.png': 80,
        'Icon-App-40x40@3x.png': 120,
        'Icon-App-60x60@2x.png': 120,
        'Icon-App-60x60@3x.png': 180,
        'Icon-App-76x76@1x.png': 76,
        'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167,
        'Icon-App-1024x1024@1x.png': 1024,
    }
    
    # Android sizes
    android_sizes = {
        'mipmap-mdpi/ic_launcher.png': 48,
        'mipmap-hdpi/ic_launcher.png': 72,
        'mipmap-xhdpi/ic_launcher.png': 96,
        'mipmap-xxhdpi/ic_launcher.png': 144,
        'mipmap-xxxhdpi/ic_launcher.png': 192,
        'playstore-icon.png': 512,
    }
    
    # Generate iOS
    ios_dir = os.path.join(output_dir, 'ios')
    os.makedirs(ios_dir, exist_ok=True)
    for name, px in ios_sizes.items():
        resized = base_img.resize((px, px), Image.LANCZOS)
        resized.save(os.path.join(ios_dir, name))
    
    # Generate Android  
    android_dir = os.path.join(output_dir, 'android')
    for name, px in android_sizes.items():
        path = os.path.join(android_dir, name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        resized = base_img.resize((px, px), Image.LANCZOS)
        resized.save(path)
    
    # Also save round icons for Android
    for name, px in android_sizes.items():
        if 'playstore' in name:
            continue
        round_name = name.replace('ic_launcher', 'ic_launcher_round')
        path = os.path.join(android_dir, round_name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        
        resized = base_img.resize((px, px), Image.LANCZOS)
        # Create circular mask
        mask = Image.new('L', (px, px), 0)
        mask_draw = ImageDraw.Draw(mask)
        mask_draw.ellipse([0, 0, px-1, px-1], fill=255)
        
        output = Image.new('RGBA', (px, px), (0, 0, 0, 0))
        output.paste(resized, mask=mask)
        output.save(path)
    
    return len(ios_sizes) + len(android_sizes) * 2

if __name__ == '__main__':
    output_dir = '/home/claude/beadot/generated_icons'
    
    print("Generating base icon (1024x1024)...")
    base = generate_icon(1024)
    base.save(os.path.join(output_dir, 'icon_1024.png') if os.path.exists(output_dir) else '/tmp/icon_1024.png')
    
    print("Generating all sizes...")
    count = generate_all_sizes(base, output_dir)
    
    print(f"Done! Generated {count} icon files in {output_dir}")
    
    # Save base to output
    os.makedirs(output_dir, exist_ok=True)
    base.save(os.path.join(output_dir, 'icon_1024.png'))
    print(f"Base icon: {output_dir}/icon_1024.png")
