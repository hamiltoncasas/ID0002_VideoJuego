#!/usr/bin/env python3
"""High-quality pixel art sprite generator for Legado Muisca."""
from PIL import Image, ImageDraw
import os

SIZE = 96  # Higher resolution for better quality
SPRITE_DIR = "assets/sprites"
os.makedirs(SPRITE_DIR, exist_ok=True)

def draw_pixel_character(draw, cx, cy, body_color, armor_color, weapon_color, has_helmet, is_hero, unit_type, team):
    """Draw a detailed pixel art character centered at (cx, cy)."""
    s = SIZE // 32  # scale reference
    bc = body_color; ac = armor_color; wc = weapon_color
    
    # Shadow
    draw.ellipse([cx - 18*s, cy + 18*s, cx + 18*s, cy + 22*s], fill=(0, 0, 0, 40))
    
    # === LEGS ===
    leg_c = (max(0, bc[0]-50), max(0, bc[1]-50), max(0, bc[2]-50), 255)
    # Left leg
    draw.polygon([(cx-9*s, cy+4*s), (cx-3*s, cy+4*s), (cx-5*s, cy+18*s), (cx-9*s, cy+18*s)], fill=leg_c)
    # Right leg
    draw.polygon([(cx+3*s, cy+4*s), (cx+9*s, cy+4*s), (cx+9*s, cy+18*s), (cx+5*s, cy+18*s)], fill=leg_c)
    
    # Boots
    for bx, by in [(-8, 15), (4, 15)]:
        draw.rectangle([cx+bx*s, cy+by*s, cx+(bx+5)*s, cy+20*s], fill=(70, 45, 25, 255))
    
    # === BODY / TUNIC ===
    body_main = bc
    # Torso
    draw.rectangle([cx-11*s, cy-8*s, cx+11*s, cy+6*s], fill=body_main)
    # Body highlight (left side)
    hl = (min(255,bc[0]+35), min(255,bc[1]+35), min(255,bc[2]+35), 200)
    draw.rectangle([cx-9*s, cy-7*s, cx-5*s, cy+4*s], fill=hl)
    # Body shadow (right side)
    sh = (max(0,bc[0]-30), max(0,bc[1]-30), max(0,bc[2]-30), 200)
    draw.rectangle([cx+5*s, cy-7*s, cx+9*s, cy+4*s], fill=sh)
    
    # Belt
    draw.rectangle([cx-10*s, cy+3*s, cx+10*s, cy+5*s], fill=(80, 60, 40, 255))
    # Belt buckle
    draw.rectangle([cx-2*s, cy+3*s, cx+2*s, cy+5*s], fill=(200, 180, 60, 255))
    
    # === ARMOR / CHEST PLATE ===
    # Main armor
    draw.rectangle([cx-8*s, cy-6*s, cx+8*s, cy+2*s], fill=ac)
    # Armor highlight
    armor_hl = (min(255,ac[0]+30), min(255,ac[1]+30), min(255,ac[2]+30), 200)
    draw.rectangle([cx-6*s, cy-5*s, cx-2*s, cy+1*s], fill=armor_hl)
    # Armor shadow
    armor_sh = (max(0,ac[0]-25), max(0,ac[1]-25), max(0,ac[2]-25), 200)
    draw.rectangle([cx+2*s, cy-5*s, cx+6*s, cy+1*s], fill=armor_sh)
    # Armor center line
    draw.line([cx, cy-6*s, cx, cy+2*s], fill=(max(0,ac[0]-40), max(0,ac[1]-40), max(0,ac[2]-40), 180), width=1)
    
    # === ARMS ===
    arm_c = (max(0,bc[0]-15), max(0,bc[1]-15), max(0,bc[2]-15), 255)
    # Left arm
    draw.rectangle([cx-14*s, cy-6*s, cx-11*s, cy+3*s], fill=arm_c)
    # Right arm (weapon arm)
    draw.rectangle([cx+11*s, cy-6*s, cx+14*s, cy+3*s], fill=arm_c)
    
    # === WEAPON ===
    if unit_type == "hero":
        # Golden sword
        draw.rectangle([cx+13*s, cy-12*s, cx+18*s, cy+2*s], fill=wc)
        draw.rectangle([cx+14*s, cy-14*s, cx+17*s, cy-10*s], fill=(255, 200, 50, 255))
        # Sword guard
        draw.rectangle([cx+12*s, cy-3*s, cx+19*s, cy-1*s], fill=(180, 150, 50, 255))
    elif unit_type == "warrior":
        # Sword
        draw.rectangle([cx+13*s, cy-10*s, cx+17*s, cy+2*s], fill=wc)
        draw.rectangle([cx+14*s, cy-12*s, cx+16*s, cy-8*s], fill=(200, 200, 210, 255))
        draw.rectangle([cx+12*s, cy-2*s, cx+18*s, cy+1*s], fill=(120, 60, 20, 255))
    elif unit_type == "archer":
        # Bow
        draw.arc([cx+12*s, cy-12*s, cx+24*s, cy+4*s], 270, 450, fill=(150, 80, 20, 255), width=3)
        # Bow string
        draw.line([cx+12*s, cy-10*s, cx+12*s, cy+2*s], fill=(200, 180, 150, 200), width=1)
    elif unit_type == "cavalry":
        # Spear
        draw.rectangle([cx+13*s, cy-16*s, cx+16*s, cy+2*s], fill=wc)
        draw.polygon([(cx+13*s, cy-18*s), (cx+16*s, cy-18*s), (cx+14.5*s, cy-22*s)], fill=(200, 200, 210, 255))
    elif unit_type == "villager":
        # Tool (axe)
        draw.rectangle([cx+13*s, cy-2*s, cx+18*s, cy+1*s], fill=(150, 100, 30, 255))
        draw.rectangle([cx+17*s, cy-5*s, cx+19*s, cy-1*s], fill=(180, 180, 190, 255))
    elif unit_type == "artisan":
        # Hammer
        draw.rectangle([cx+13*s, cy-2*s, cx+17*s, cy+1*s], fill=(120, 80, 30, 255))
        draw.rectangle([cx+16*s, cy-5*s, cx+18*s, cy-1*s], fill=(200, 200, 50, 255))
    
    # === HEAD ===
    head_c = (min(255,bc[0]+10), min(255,bc[1]+10), min(255,bc[2]+10), 255)
    # Face circle
    draw.ellipse([cx-8*s, cy-18*s, cx+8*s, cy-4*s], fill=head_c)
    # Face highlight
    draw.ellipse([cx-5*s, cy-17*s, cx+2*s, cy-12*s], fill=(min(255,head_c[0]+20), min(255,head_c[1]+20), min(255,head_c[2]+20), 120))
    
    # === EYES ===
    # White
    draw.ellipse([cx-5*s, cy-13*s, cx-1*s, cy-10*s], fill=(235, 235, 245, 255))
    draw.ellipse([cx+1*s, cy-13*s, cx+5*s, cy-10*s], fill=(235, 235, 245, 255))
    # Pupil
    draw.ellipse([cx-4*s, cy-12*s, cx-2*s, cy-11*s], fill=(20, 20, 50, 255))
    draw.ellipse([cx+2*s, cy-12*s, cx+4*s, cy-11*s], fill=(20, 20, 50, 255))
    # Catchlights
    draw.ellipse([cx-3*s, cy-13*s, cx-2*s, cy-12*s], fill=(255, 255, 255, 220))
    draw.ellipse([cx+3*s, cy-13*s, cx+4*s, cy-12*s], fill=(255, 255, 255, 220))
    
    # Eyebrows
    draw.line([cx-6*s, cy-15*s, cx-2*s, cy-14.5*s], fill=(40, 20, 10, 200), width=2)
    draw.line([cx+2*s, cy-14.5*s, cx+6*s, cy-15*s], fill=(40, 20, 10, 200), width=2)
    
    # === HAIR / HELMET ===
    if has_helmet or is_hero:
        # Helmet
        helm_color = (180, 50, 50, 230) if not is_hero else (200, 170, 50, 230)
        draw.rectangle([cx-8*s, cy-21*s, cx+8*s, cy-16*s], fill=helm_color)
        # Helmet highlight
        hh = (min(255,helm_color[0]+40), min(255,helm_color[1]+40), min(255,helm_color[2]+40), 200)
        draw.rectangle([cx-6*s, cy-20*s, cx-2*s, cy-17*s], fill=hh)
        # Helmet plume (hero)
        if is_hero:
            draw.ellipse([cx-3*s, cy-25*s, cx+3*s, cy-19*s], fill=(220, 50, 50, 230))
        # Visor
        draw.rectangle([cx-7*s, cy-17*s, cx+7*s, cy-16*s], fill=(40, 40, 40, 200))
    else:
        # Hair
        hair_colors = [(100, 50, 20, 230), (80, 40, 15, 200), (60, 30, 10, 180)]
        for i, hc in enumerate(hair_colors):
            dy = i * 2
            draw.arc([cx-8*s, cy-18*s+dy, cx+8*s, cy-10*s+dy], 180, 360, fill=hc, width=4)
    
    # === HERO AURA ===
    if is_hero:
        for r in range(20, 26, 3):
            draw.ellipse([cx-r*s, cy-r*s-2, cx+r*s, cy+r*s-2], outline=(255, 220, 50, 15), width=2)

def create_unit_sprite(unit_type, team, body_color, armor_color=None, weapon_color=None, has_helmet=False, is_hero=False):
    """Create a full character sprite."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2
    
    if armor_color is None: armor_color = (min(255,body_color[0]+10), min(255,body_color[1]-10), min(255,body_color[2]-10), 255)
    if weapon_color is None: weapon_color = (200, 200, 210, 255)
    
    # For enemy team, darken colors
    if team == "enemy":
        body_color = (body_color[0]//2, body_color[1]//3, body_color[2]//3, 255)
        armor_color = (armor_color[0]//2, armor_color[1]//3, armor_color[2]//3, 255)
    
    draw_pixel_character(draw, cx, cy, body_color, armor_color, weapon_color, has_helmet, is_hero, unit_type, team)
    return img

def create_building_sprite(building_type, size=96):
    """Generate building sprites with detail."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    
    config = {
        "castle": {"walls": (140, 85, 45), "roof": (160, 50, 50), "h": 1.0},
        "barracks": {"walls": (160, 95, 50), "roof": (180, 100, 60), "h": 0.7},
        "archery": {"walls": (130, 85, 45), "roof": (170, 120, 70), "h": 0.65},
        "stable": {"walls": (150, 100, 50), "roof": (160, 130, 80), "h": 0.65},
        "wall": {"walls": (130, 105, 70), "roof": (110, 95, 65), "h": 0.4},
        "tower_arrow": {"walls": (140, 90, 50), "roof": (160, 50, 50), "h": 0.8},
    }
    cfg = config.get(building_type, config["castle"])
    
    w = int(size * 0.55); h = int(size * cfg["h"] * 0.5)
    wx, wy = cx - w//2, cy - h//2 + 10
    
    # Shadow
    draw.ellipse([cx - w//2 - 5, cy + h//2, cx + w//2 + 5, cy + h//2 + 10], fill=(0, 0, 0, 40))
    
    # Walls
    for layer in range(3):
        offset = layer * 3
        lc = (cfg["walls"][0]-layer*15, cfg["walls"][1]-layer*10, cfg["walls"][2]-layer*5, 255)
        draw.rectangle([wx-offset, wy+offset, wx+w+offset, wy+h+offset], fill=lc)
    
    # Wall texture (brick lines)
    for row in range(0, h, 8):
        draw.line([wx, wy+row, wx+w, wy+row], fill=(cfg["walls"][0]-30, cfg["walls"][1]-20, cfg["walls"][2]-10, 100), width=1)
    for col in range(0, w, 12):
        draw.line([wx+col, wy, wx+col, wy+h], fill=(cfg["walls"][0]-30, cfg["walls"][1]-20, cfg["walls"][2]-10, 100), width=1)
    
    # Door
    door_w = w//4; door_h = h//2
    draw.rectangle([cx - door_w//2, wy + h - door_h, cx + door_w//2, wy + h], fill=(60, 40, 20, 255))
    # Door arch
    draw.arc([cx - door_w//2, wy + h - door_h - 5, cx + door_w//2, wy + h - door_h + 5], 0, 180, fill=(60, 40, 20, 255), width=3)
    
    # Windows
    win_w = w//6; win_h = h//5
    for side in [-1, 1]:
        win_x = cx + side * w//4 - win_w//2
        win_y = wy + h//4
        draw.rectangle([win_x, win_y, win_x+win_w, win_y+win_h], fill=(200, 180, 100, 220))
        draw.rectangle([win_x, win_y, win_x+win_w, win_y+win_h], outline=(60, 40, 20, 200), width=1)
        # Window cross
        draw.line([win_x+win_w//2, win_y, win_x+win_w//2, win_y+win_h], fill=(60, 40, 20, 150), width=1)
        draw.line([win_x, win_y+win_h//2, win_x+win_w, win_y+win_h//2], fill=(60, 40, 20, 150), width=1)
    
    # Roof
    roof_h = h // 3
    roof_points = [(wx-8, wy), (cx, wy-roof_h), (wx+w+8, wy)]
    draw.polygon(roof_points, fill=cfg["roof"])
    # Roof highlight
    hl_roof = (min(255,cfg["roof"][0]+30), min(255,cfg["roof"][1]+30), min(255,cfg["roof"][2]+30), 200)
    draw.polygon([(wx-4, wy), (cx, wy-roof_h+5), (cx-w//4, wy)], fill=hl_roof)
    # Roof tiles (lines)
    for ry in range(0, roof_h, 6):
        rl_x = int(cx - (w//2+8) * (1 - ry/roof_h))
        rr_x = int(cx + (w//2+8) * (1 - ry/roof_h))
        draw.line([rl_x, wy-ry, rr_x, wy-ry], fill=(max(0,cfg["roof"][0]-40), max(0,cfg["roof"][1]-40), max(0,cfg["roof"][2]-40), 80), width=1)
    
    # Flag on top (for castle)
    if building_type == "castle":
        flag_x = cx
        flag_y = wy - roof_h - 10
        draw.line([flag_x, flag_y, flag_x, flag_y+15], fill=(100, 80, 50, 255), width=2)
        draw.polygon([(flag_x, flag_y), (flag_x+12, flag_y+4), (flag_x, flag_y+8)], fill=(200, 50, 50, 255))
    
    return img

def create_tree_sprite(variant=0, size=64):
    """Generate detailed tree sprite."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    
    # Shadow
    draw.ellipse([cx - size//3, cy + size//5, cx + size//3, cy + size//4], fill=(0, 0, 0, 30))
    
    # Trunk
    trunk_w = 6 + variant * 2
    draw.rectangle([cx - trunk_w//2, cy - 4, cx + trunk_w//2, cy + size//4], fill=(90, 60, 25, 255))
    draw.rectangle([cx - trunk_w//4, cy - 4, cx + trunk_w//4, cy + size//4], fill=(110, 75, 35, 180))
    
    # Foliage layers
    foliage_colors = [
        [(40, 100, 35), (50, 120, 40), (60, 140, 50)],
        [(35, 90, 40), (45, 110, 45), (55, 130, 55)],
        [(45, 110, 30), (55, 130, 40), (65, 150, 50)],
    ]
    colors = foliage_colors[variant % 3]
    
    # Bottom layer
    r1 = size // 3 + variant * 2
    draw.ellipse([cx - r1, cy - 5, cx + r1, cy + 15], fill=colors[2] + (255,))
    # Middle layer
    r2 = r1 - 5
    draw.ellipse([cx - r2, cy - 12, cx + r2, cy + 5], fill=colors[1] + (255,))
    # Top layer
    r3 = r2 - 6
    draw.ellipse([cx - r3, cy - 20, cx + r3, cy - 2], fill=colors[0] + (255,))
    
    # Highlight
    draw.ellipse([cx - 4, cy - 18, cx + 2, cy - 10], fill=(120, 200, 80, 120))
    
    return img

def generate_all():
    """Generate all game sprites."""
    unit_configs = [
        ("hero", "player", (240, 170, 30), None, None, True, True),
        ("warrior", "player", (180, 100, 50), (160, 130, 100), (190, 190, 210), True, False),
        ("archer", "player", (80, 150, 80), (130, 100, 60), (160, 90, 30), False, False),
        ("cavalry", "player", (200, 130, 50), (150, 120, 80), (190, 190, 210), True, False),
        ("villager", "player", (150, 100, 70), (130, 110, 80), (160, 120, 60), False, False),
        ("artisan", "player", (180, 150, 50), (160, 140, 70), (210, 190, 60), False, False),
    ]
    
    buildings = ["castle", "barracks", "archery", "stable", "wall", "tower_arrow"]
    
    print("Generating characters...")
    for name, team, bc, ac, wc, helm, hero in unit_configs:
        img = create_unit_sprite(name, team, bc, ac, wc, helm, hero)
        img.save(os.path.join(SPRITE_DIR, f"{name}.png"))
        print(f"  ✅ {name}.png")
        
        img_e = create_unit_sprite(name, "enemy", bc, ac, wc, helm, False)
        img_e.save(os.path.join(SPRITE_DIR, f"enemy_{name}.png"))
        print(f"  ✅ enemy_{name}.png")
    
    print("\nGenerating buildings...")
    for b in buildings:
        img = create_building_sprite(b)
        img.save(os.path.join(SPRITE_DIR, f"building_{b}.png"))
        print(f"  ✅ building_{b}.png")
    
    print("\nGenerating trees...")
    for v in range(3):
        img = create_tree_sprite(v)
        img.save(os.path.join(SPRITE_DIR, f"tree_{v}.png"))
        print(f"  ✅ tree_{v}.png")
    
    print(f"\nTotal: {len(os.listdir(SPRITE_DIR))} sprites")

if __name__ == "__main__":
    generate_all()
