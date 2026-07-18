#!/usr/bin/env python3
"""Generate high-quality pixel art sprites for all game units."""
from PIL import Image, ImageDraw
import os, json

SPRITE_DIR = "assets/sprites"
os.makedirs(SPRITE_DIR, exist_ok=True)

def create_unit_sprite(name, body_color, armor_color, weapon_color, has_helmet=False, is_hero=False, size=64):
    """Generate a detailed pixel art character sprite."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    
    # Helper functions
    def rect(x1, y1, x2, y2, color):
        draw.rectangle([x1, y1, x2, y2], fill=color)
    
    def circle(cx, cy, r, color):
        draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=color)
    
    def rgba(c, a=255):
        return (int(c[0]*255), int(c[1]*255), int(c[2]*255), a) if isinstance(c, (list, tuple)) else c
    
    bc = rgba(body_color, 255)
    ac = rgba(armor_color, 255) if armor_color else (180, 180, 180, 255)
    wc = rgba(weapon_color, 255) if weapon_color else (200, 200, 200, 255)
    
    size_s = size // 64  # scale factor
    
    # Shadow
    draw.ellipse([cx - 12*size_s, cy + 8*size_s, cx + 12*size_s, cy + 14*size_s], fill=(0, 0, 0, 40))
    
    # Legs
    lc = (max(0,bc[0]-40), max(0,bc[1]-40), max(0,bc[2]-40), 255)
    draw.rectangle([cx - 8*size_s, cy + 4*size_s, cx - 3*size_s, cy + 14*size_s], fill=lc)
    draw.rectangle([cx + 3*size_s, cy + 4*size_s, cx + 8*size_s, cy + 14*size_s], fill=lc)
    
    # Boots
    draw.rectangle([cx - 9*size_s, cy + 11*size_s, cx - 2*size_s, cy + 14*size_s], fill=(80, 50, 30, 255))
    draw.rectangle([cx + 2*size_s, cy + 11*size_s, cx + 9*size_s, cy + 14*size_s], fill=(80, 50, 30, 255))
    
    # Tunic/body
    draw.rectangle([cx - 10*size_s, cy - 6*size_s, cx + 10*size_s, cy + 6*size_s], fill=bc)
    
    # Body highlight
    draw.rectangle([cx - 8*size_s, cy - 5*size_s, cx - 3*size_s, cy + 4*size_s], 
                  fill=(min(255,bc[0]+30), min(255,bc[1]+30), min(255,bc[2]+30), 180))
    
    # Armor / chest plate
    draw.rectangle([cx - 7*size_s, cy - 3*size_s, cx + 7*size_s, cy + 3*size_s], fill=ac)
    # Armor line detail
    draw.line([cx - 5*size_s, cy - 1*size_s, cx + 5*size_s, cy - 1*size_s], 
             fill=(ac[0]//2, ac[1]//2, ac[2]//2, 255), width=2)
    
    # Arms
    arm_c = (max(0,bc[0]-20), max(0,bc[1]-20), max(0,bc[2]-20), 255)
    draw.rectangle([cx - 13*size_s, cy - 4*size_s, cx - 10*size_s, cy + 2*size_s], fill=arm_c)
    draw.rectangle([cx + 10*size_s, cy - 4*size_s, cx + 13*size_s, cy + 2*size_s], fill=arm_c)
    
    # Weapon (right arm)
    if is_hero:
        draw.rectangle([cx + 12*size_s, cy - 8*size_s, cx + 16*size_s, cy + 1*size_s], fill=wc)
        draw.rectangle([cx + 14*size_s, cy - 10*size_s, cx + 16*size_s, cy - 5*size_s], fill=(220, 180, 50, 255))
    elif name == "warrior":
        draw.rectangle([cx + 12*size_s, cy - 6*size_s, cx + 18*size_s, cy + 1*size_s], fill=wc)
        draw.rectangle([cx + 12*size_s, cy - 3*size_s, cx + 14*size_s, cy + 1*size_s], fill=(120, 60, 20, 255))
    elif name == "archer":
        draw.line([cx + 10*size_s, cy - 2*size_s, cx + 22*size_s, cy - 12*size_s], fill=(150, 80, 20, 255), width=3)
        draw.line([cx + 22*size_s, cy - 12*size_s, cx + 18*size_s, cy - 2*size_s], fill=(150, 80, 20, 255), width=2)
    elif name == "cavalry":
        draw.rectangle([cx + 12*size_s, cy - 8*size_s, cx + 18*size_s, cy + 1*size_s], fill=wc)
        draw.rectangle([cx - 8*size_s, cy + 2*size_s, cx + 12*size_s, cy + 8*size_s], fill=(max(0,bc[0]-40), max(0,bc[1]-20), max(0,bc[2]-20), 200))
    elif name == "villager":
        draw.rectangle([cx + 12*size_s, cy + 0*size_s, cx + 16*size_s, cy + 4*size_s], fill=(150, 100, 30, 255))
    elif name == "artisan":
        draw.rectangle([cx + 12*size_s, cy + 0*size_s, cx + 15*size_s, cy + 3*size_s], fill=(200, 180, 50, 255))
    
    # Head
    hc = bc
    draw.ellipse([cx - 7*size_s, cy - 17*size_s, cx + 7*size_s, cy - 3*size_s], fill=hc)
    # Head highlight
    draw.ellipse([cx - 5*size_s, cy - 16*size_s, cx + 3*size_s, cy - 10*size_s], 
                fill=(min(255,bc[0]+25), min(255,bc[1]+25), min(255,bc[2]+25), 100))
    
    # Eyes
    draw.ellipse([cx - 4*size_s, cy - 12*size_s, cx - 1*size_s, cy - 9*size_s], fill=(230, 230, 245, 255))
    draw.ellipse([cx + 1*size_s, cy - 12*size_s, cx + 4*size_s, cy - 9*size_s], fill=(230, 230, 245, 255))
    # Pupil
    draw.ellipse([cx - 3*size_s, cy - 11*size_s, cx - 2*size_s, cy - 10*size_s], fill=(20, 20, 50, 255))
    draw.ellipse([cx + 2*size_s, cy - 11*size_s, cx + 3*size_s, cy - 10*size_s], fill=(20, 20, 50, 255))
    # Catchlight
    draw.ellipse([cx - 2*size_s, cy - 12*size_s, cx - 1*size_s, cy - 11*size_s], fill=(245, 245, 255, 220))
    draw.ellipse([cx + 3*size_s, cy - 12*size_s, cx + 4*size_s, cy - 11*size_s], fill=(245, 245, 255, 220))
    
    # Helmet / hair
    if has_helmet or is_hero:
        draw.rectangle([cx - 7*size_s, cy - 16*size_s, cx + 7*size_s, cy - 13*size_s], fill=(180, 50, 50, 200))
        if is_hero:
            draw.rectangle([cx - 5*size_s, cy - 19*size_s, cx + 5*size_s, cy - 16*size_s], fill=(200, 170, 50, 200))
    else:
        # Hair
        draw.arc([cx - 7*size_s, cy - 16*size_s, cx + 7*size_s, cy - 10*size_s], 180, 360, fill=(120, 60, 20, 200), width=3)
    
    # Hero aura glow
    if is_hero:
        for r in range(18, 22, 2):
            draw.ellipse([cx - r*size_s, cy - r*size_s - 2, cx + r*size_s, cy + r*size_s - 2], 
                        outline=(255, 220, 50, 20), width=2)
    
    return img

def save_character_sheet():
    """Generate all unit sprites."""
    units = {
        "hero": ((255, 180, 25), (180, 140, 60), (255, 220, 100), True, True),
        "warrior": ((180, 100, 50), (160, 130, 100), (180, 180, 200), True, False),
        "archer": ((80, 150, 80), (130, 100, 60), (160, 90, 30), False, False),
        "cavalry": ((200, 130, 50), (150, 120, 80), (180, 180, 200), True, False),
        "villager": ((150, 100, 70), (130, 110, 80), (160, 120, 60), False, False),
        "artisan": ((180, 150, 50), (160, 140, 70), (200, 180, 60), False, False),
    }
    
    for name, (bc, ac, wc, helm, hero) in units.items():
        img = create_unit_sprite(name, bc, ac, wc, helm, hero)
        path = os.path.join(SPRITE_DIR, f"{name}.png")
        img.save(path)
        print(f"  ✅ {name}.png")
    
    # Also generate enemy versions (darker)
    for name, (bc, ac, wc, helm, hero) in units.items():
        ebc = (bc[0]//2, bc[1]//3, bc[2]//3)
        eac = (ac[0]//2, ac[1]//3, ac[2]//3)
        ewc = (wc[0]//2, wc[1]//2, wc[2]//2)
        img = create_unit_sprite(f"enemy_{name}", ebc, eac, ewc, helm, False)
        path = os.path.join(SPRITE_DIR, f"enemy_{name}.png")
        img.save(path)
        print(f"  ✅ enemy_{name}.png")

def create_building_sprite(name, base_color, roof_color, w=96, h=96):
    """Generate building sprites like castle, barracks, etc."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = w // 2, h // 2
    
    # Shadow
    draw.ellipse([cx - w//3, cy + h//4, cx + w//3, cy + h//3], fill=(0, 0, 0, 40))
    
    # Walls
    wall_color = base_color
    draw.rectangle([cx - w//3, cy - h//6, cx + w//3, cy + h//4], fill=wall_color)
    
    # Roof
    roof = roof_color
    draw.polygon([(cx - w//3 - 5, cy - h//6), (cx, cy - h//3), (cx + w//3 + 5, cy - h//6)], fill=roof)
    
    # Door
    draw.rectangle([cx - 8, cy - 5, cx + 8, cy + h//4], fill=(80, 50, 30, 255))
    
    # Windows
    for wx in [-w//6, w//6]:
        draw.rectangle([cx + wx - 5, cy - 15, cx + wx + 5, cy - 5], fill=(200, 180, 100, 200))
    
    return img

def create_tree_sprite(size=64):
    """Generate tree sprites."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    
    # Shadow
    draw.ellipse([cx - size//4, cy + size//6, cx + size//4, cy + size//4], fill=(0, 0, 0, 30))
    
    # Trunk
    draw.rectangle([cx - 3, cy - 5, cx + 3, cy + size//4], fill=(100, 65, 30, 255))
    
    # Foliage layers
    colors = [(40, 120, 40, 255), (50, 140, 50, 240), (60, 160, 60, 220)]
    for i, c in enumerate(colors):
        r = size//4 - i*4
        draw.ellipse([cx - r, cy - size//3 - 5 + i*8, cx + r, cy - size//6 + i*8], fill=c)
    
    # Highlight
    draw.ellipse([cx - 5, cy - size//3 - 2, cx + 3, cy - size//4], fill=(100, 200, 100, 120))
    
    return img

def save_all_sprites():
    """Generate all game sprites."""
    print("Generating character sprites...")
    save_character_sheet()
    
    print("\nGenerating building sprites...")
    buildings = [
        ("castle", (130, 80, 40), (180, 50, 50)),
        ("barracks", (150, 90, 50), (180, 100, 60)),
        ("archery", (120, 80, 40), (170, 120, 70)),
        ("stable", (140, 95, 45), (160, 130, 80)),
        ("wall", (120, 100, 70), (100, 90, 60)),
        ("tower_arrow", (130, 85, 45), (160, 50, 50)),
    ]
    for name, bc, rc in buildings:
        img = create_building_sprite(name, bc, rc)
        path = os.path.join(SPRITE_DIR, f"building_{name}.png")
        img.save(path)
        print(f"  ✅ building_{name}.png")
    
    print("\nGenerating tree sprites...")
    for i in range(3):
        img = create_tree_sprite()
        path = os.path.join(SPRITE_DIR, f"tree_{i}.png")
        img.save(path)
        print(f"  ✅ tree_{i}.png")

if __name__ == "__main__":
    save_all_sprites()
    print(f"\nAll sprites saved to {SPRITE_DIR}/")
    print("Total files:", len(os.listdir(SPRITE_DIR)))

if __name__ == "__main__":
    print("Generating sprites...")
    save_character_sheet()
    print(f"\nAll sprites saved to {SPRITE_DIR}/")
    print("Total files:", len(os.listdir(SPRITE_DIR)))
