#!/usr/bin/env python3
"""Pseudo-3D sprite generator with shadows, depth, and lighting."""
from PIL import Image, ImageDraw
import os, math

SIZE = 128  # Higher res for better quality
SPRITE_DIR = "assets/sprites"
os.makedirs(SPRITE_DIR, exist_ok=True)

def drop_shadow(draw, bx, by, bw, bh, intensity=40, spread=6):
    """Draw a soft drop shadow under an element."""
    for i in range(spread):
        alpha = intensity - i * (intensity // spread)
        if alpha <= 0: continue
        draw.ellipse([bx - i, by - i + bh//2, bx + bw + i, by + bh//2 + i], 
                     fill=(0, 0, 0, alpha // 2))

def draw_3d_box(draw, cx, cy, w, h, top_color, front_color, side_color, depth=6):
    """Draw a pseudo-3D box with top, front, and side faces."""
    hw, hh = w // 2, h // 2
    # Front face
    draw.rectangle([cx - hw, cy - hh//2, cx + hw, cy + hh//2], fill=front_color)
    # Top face (tilted)
    top_pts = [(cx - hw, cy - hh//2 - depth), (cx, cy - hh//2 - depth - hw//4),
               (cx + hw, cy - hh//2 - depth), (cx + hw, cy - hh//2), (cx - hw, cy - hh//2)]
    draw.polygon(top_pts, fill=top_color)
    # Side face (right)
    side_pts = [(cx + hw, cy - hh//2), (cx + hw, cy - hh//2 - depth),
                (cx + hw, cy + hh//2 - depth), (cx + hw, cy + hh//2)]
    draw.polygon(side_pts, fill=side_color)

def draw_pseudo_3d_character(draw, cx, cy, bc, ac, wc, unit_type, is_hero, has_helmet, team):
    """Draw character with 3D-like shading and depth."""
    s = SIZE // 40  # scale factor
    shade = 0.7 if team == "enemy" else 1.0
    
    def col(c, mult=1.0):
        return (min(255, int(c[0]*mult*shade)), min(255, int(c[1]*mult*shade)), min(255, int(c[2]*mult*shade)), 255)
    
    # === GROUND SHADOW ===
    shadow_alpha = 50 if team == "player" else 30
    for i in range(8, 0, -1):
        a = shadow_alpha - i * 5
        if a <= 0: continue
        draw.ellipse([cx - 22*s - i, cy + 16*s - i//2, cx + 22*s + i, cy + 22*s + i//2], 
                     fill=(0, 0, 0, a))
    
    # === LEGS ===
    leg_c = col(bc, 0.6)
    # Left leg with 3D shading
    for ix in range(3):
        lc = (leg_c[0]-ix*10, leg_c[1]-ix*8, leg_c[2]-ix*6, 255) if ix < 2 else leg_c
        draw.rectangle([cx - 10*s + ix, cy + 4*s, cx - 4*s + ix, cy + 18*s], fill=lc)
    # Right leg
    for ix in range(3):
        lc = (leg_c[0]-ix*10, leg_c[1]-ix*8, leg_c[2]-ix*6, 255) if ix < 2 else leg_c
        draw.rectangle([cx + 4*s + ix, cy + 4*s, cx + 10*s + ix, cy + 18*s], fill=lc)
    
    # Boots
    boot_c = (60, 40, 25, 255)
    draw.rectangle([cx - 11*s, cy + 15*s, cx - 3*s, cy + 20*s], fill=boot_c)
    draw.rectangle([cx + 3*s, cy + 15*s, cx + 11*s, cy + 20*s], fill=boot_c)
    # Boot shine
    draw.rectangle([cx - 9*s, cy + 16*s, cx - 6*s, cy + 18*s], fill=(80, 55, 35, 200))
    draw.rectangle([cx + 5*s, cy + 16*s, cx + 8*s, cy + 18*s], fill=(80, 55, 35, 200))
    
    # === BODY ===
    body_main = col(bc)
    # Torso with 3D cylinder shading
    grad_steps = 9
    for i in range(grad_steps):
        frac = (i - grad_steps//2) / (grad_steps//2)
        brightness = 1.0 - 0.15 * abs(frac) + 0.1 * (1 if frac < 0 else -1)
        bx = cx - 11*s + i * 3*s
        bw = 3*s + 1
        bw = min(bw, cx + 11*s - bx)
        if bw <= 0: break
        bcol = col(bc, brightness)
        draw.rectangle([bx, cy - 8*s, bx + bw, cy + 6*s], fill=bcol)
    
    # Belt
    draw.rectangle([cx - 11*s, cy + 3*s, cx + 11*s, cy + 5*s], fill=(70, 50, 30, 255))
    draw.rectangle([cx - 2*s, cy + 3*s, cx + 2*s, cy + 5*s], fill=(200, 180, 60, 255))
    
    # === ARMOR (3D chest plate) ===
    armor = col(ac, 0.9)
    # Main plate with gradient
    for i in range(7):
        frac = (i - 3) / 3
        brightness = 1.0 - 0.2 * abs(frac)
        bx = cx - 7*s + i * 3*s
        bw = 3*s
        bcol = col(ac, brightness)
        draw.rectangle([bx, cy - 5*s, bx + bw, cy + 2*s], fill=bcol)
    
    # Armor edge
    draw.rectangle([cx - 8*s, cy - 6*s, cx + 8*s, cy - 5*s], fill=col(ac, 0.7))
    draw.rectangle([cx - 8*s, cy + 1*s, cx + 8*s, cy + 2*s], fill=col(ac, 0.7))
    # Armor center ridge
    draw.line([cx, cy - 5*s, cx, cy + 2*s], fill=(200, 200, 180, 150), width=2)
    
    # === ARMS ===
    arm_c = col(bc, 0.8)
    # Left arm
    for i in range(3):
        draw.rectangle([cx - 15*s + i, cy - 6*s, cx - 11*s + i, cy + 3*s], 
                       fill=(arm_c[0]-i*8, arm_c[1]-i*8, arm_c[2]-i*8, 255))
    # Right arm
    for i in range(3):
        draw.rectangle([cx + 11*s + i, cy - 6*s, cx + 15*s + i, cy + 3*s], 
                       fill=(arm_c[0]-i*8, arm_c[1]-i*8, arm_c[2]-i*8, 255))
    
    # === WEAPON ===
    if unit_type == "hero":
        # Golden blade with gradient
        for i in range(4):
            wcol = (220 - i*20, 180 - i*15, 40 + i*10, 255)
            draw.rectangle([cx + 14*s + i, cy - 14*s, cx + 17*s - i, cy - 2*s], fill=wcol)
        draw.rectangle([cx + 13*s, cy - 3*s, cx + 18*s, cy - 1*s], fill=(180, 150, 50, 255))
        # Hilt
        draw.rectangle([cx + 13*s, cy - 1*s, cx + 18*s, cy + 2*s], fill=(100, 60, 20, 255))
        draw.ellipse([cx + 14*s, cy - 15*s, cx + 17*s, cy - 12*s], fill=(255, 220, 60, 255))
    elif unit_type == "warrior":
        for i in range(3):
            draw.rectangle([cx + 13*s + i, cy - 12*s, cx + 16*s - i, cy + 2*s], fill=(180-i*20, 180-i*20, 190-i*15, 255))
        draw.rectangle([cx + 12*s, cy - 2*s, cx + 17*s, cy + 1*s], fill=(110, 60, 20, 255))
    elif unit_type == "archer":
        draw.arc([cx + 12*s, cy - 14*s, cx + 26*s, cy + 4*s], 270, 450, fill=(140, 75, 20, 255), width=3)
        draw.arc([cx + 12*s, cy - 14*s, cx + 26*s, cy + 4*s], 270, 450, fill=(col(ac, 0.5)), width=2)
        draw.line([cx + 12*s, cy - 11*s, cx + 12*s, cy + 2*s], fill=(200, 180, 150, 200), width=1)
    elif unit_type == "cavalry":
        for i in range(3):
            draw.rectangle([cx + 13*s + i, cy - 18*s, cx + 16*s - i, cy + 2*s], fill=(180-i*20, 180-i*20, 190-i*15, 255))
        draw.polygon([(cx+13*s, cy-20*s), (cx+16*s, cy-20*s), (cx+14.5*s, cy-24*s)], fill=(200, 200, 210, 255))
        # Horse body (partial)
        horse_c = col(bc, 0.6)
        draw.ellipse([cx - 6*s, cy + 3*s, cx + 12*s, cy + 12*s], fill=horse_c)
    elif unit_type == "villager":
        draw.rectangle([cx + 13*s, cy - 2*s, cx + 19*s, cy + 1*s], fill=(140, 90, 25, 255))
        draw.rectangle([cx + 17*s, cy - 6*s, cx + 20*s, cy - 1*s], fill=(170, 170, 180, 255))
    elif unit_type == "artisan":
        draw.rectangle([cx + 13*s, cy - 2*s, cx + 18*s, cy + 1*s], fill=(110, 70, 20, 255))
        draw.rectangle([cx + 16*s, cy - 6*s, cx + 19*s, cy - 1*s], fill=(220, 210, 50, 255))
    
    # === HEAD (sphere with 3D shading) ===
    head_c = col(bc, 1.05)
    for r in range(8*s, 0, -2):
        frac = r / (8*s)
        bright = 0.85 + 0.15 * (1 - frac)
        hcol = col(bc, bright)
        y1 = cy - 18*s + int((8*s - r) * 0.5)
        y2 = cy - 4*s - int((8*s - r) * 0.5)
        if y1 >= y2:
            y1 = y2 - 1
        draw.ellipse([cx - r, y1, cx + r, y2], fill=hcol)
    
    # === EYES with depth ===
    # Left eye socket
    draw.ellipse([cx - 6*s, cy - 14*s, cx - 2*s, cy - 10*s], fill=(180, 180, 190, 200))
    draw.ellipse([cx - 5*s, cy - 13*s, cx - 3*s, cy - 11*s], fill=(235, 235, 245, 255))
    draw.ellipse([cx - 4.5*s, cy - 12.5*s, cx - 3.5*s, cy - 11.5*s], fill=(15, 15, 40, 255))
    draw.ellipse([cx - 4*s, cy - 13*s, cx - 3.5*s, cy - 12.5*s], fill=(255, 255, 255, 200))
    # Right eye socket
    draw.ellipse([cx + 2*s, cy - 14*s, cx + 6*s, cy - 10*s], fill=(180, 180, 190, 200))
    draw.ellipse([cx + 3*s, cy - 13*s, cx + 5*s, cy - 11*s], fill=(235, 235, 245, 255))
    draw.ellipse([cx + 3.5*s, cy - 12.5*s, cx + 4.5*s, cy - 11.5*s], fill=(15, 15, 40, 255))
    draw.ellipse([cx + 3.5*s, cy - 13*s, cx + 4*s, cy - 12.5*s], fill=(255, 255, 255, 200))
    
    # Eyebrows
    draw.line([cx - 7*s, cy - 16*s, cx - 2*s, cy - 15*s], fill=(40, 20, 10, 200), width=2)
    draw.line([cx + 2*s, cy - 15*s, cx + 7*s, cy - 16*s], fill=(40, 20, 10, 200), width=2)
    
    # === HAIR / HELMET ===
    if has_helmet or is_hero:
        helm_h = col((200, 50, 50), 1) if not is_hero else col((220, 180, 40), 1)
        for i in range(8*s, 0, -3):
            frac = i / (8*s)
            hcol = col(helm_h, 0.8 + 0.2 * (1 - frac))
            y1 = cy - 22*s + int((8*s - i) * 0.5)
            y2 = cy - 15*s - int((8*s - i) * 0.5)
            if y1 >= y2: y1 = y2 - 1
            if y1 < 0: break
            draw.arc([cx - i, y1, cx + i, y2], 200, 340, fill=hcol, width=3)
        # Visor
        draw.rectangle([cx - 7*s, cy - 17*s, cx + 7*s, cy - 16*s], fill=(30, 30, 30, 230))
        # Helmet highlight
        draw.arc([cx - 4*s, cy - 22*s, cx + 4*s, cy - 18*s], 200, 340, fill=(255, 255, 255, 120), width=2)
        # Plume (hero)
        if is_hero:
            draw.ellipse([cx - 4*s, cy - 26*s, cx + 4*s, cy - 20*s], fill=(230, 50, 50, 230))
            draw.ellipse([cx - 2*s, cy - 26*s, cx + 1*s, cy - 23*s], fill=(255, 100, 100, 150))
    else:
        hair_c = (100, 50, 20, 230)
        for i in range(6*s, 0, -2):
            draw.arc([cx - i, cy - 18*s, cx + i, cy - 10*s], 190, 350, fill=(hair_c[0]-i*3, hair_c[1]-i*2, hair_c[2]-i, 230), width=3)
    
    # === HERO GLOW ===
    if is_hero:
        for r in range(24, 30, 2):
            glow_a = 20 - (r - 24) * 3
            if glow_a <= 0: continue
            draw.ellipse([cx - r*s, cy - r*s, cx + r*s, cy + r*s], outline=(255, 220, 50, glow_a), width=2)

def create_unit(name, team, body_c, armor_c=None, weapon_c=None, helm=False, hero=False):
    """Create full character sprite with 3D shading."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    if armor_c is None: armor_c = tuple(min(255, c+10) for c in body_c)
    if weapon_c is None: weapon_c = (200, 200, 210)
    draw_pseudo_3d_character(draw, SIZE//2, SIZE//2, body_c, armor_c, weapon_c, name, hero, helm, team)
    return img

def create_building(name, size=SIZE):
    """Create building with 3D perspective."""
    img = Image.new("RGBA", (size, size+20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size//2, size//2 - 10
    
    cfg = {"castle": [(140,85,45),(160,50,50),(200,50,50),1.0],
           "barracks": [(160,95,50),(180,100,60),(200,80,60),0.7],
           "archery": [(130,85,45),(170,120,70),(190,100,70),0.65],
           "stable": [(150,100,50),(160,130,80),(180,120,70),0.65],
           "wall": [(130,105,70),(110,95,65),(140,110,80),0.35],
           "tower_arrow": [(140,90,50),(160,50,50),(200,70,60),0.8]}
    walls, roof, roof2, h = cfg.get(name, cfg["castle"])
    
    w = int(size * 0.55); bh = int(size * h * 0.45)
    wx, wy = cx - w//2, cy - bh//2
    
    # Ground shadow
    for i in range(10, 0, -1):
        a = 35 - i * 3
        if a <= 0: continue
        draw.ellipse([cx - w//2 - 10 - i, cy + bh//2 + i - 5, cx + w//2 + 10 + i, cy + bh//2 + 15 + i], fill=(0, 0, 0, a))
    
    # Walls with 3D texture
    for layer in range(5):
        off = layer * 2
        lc = (walls[0]-layer*10, walls[1]-layer*6, walls[2]-layer*4, 255)
        draw.rectangle([wx-off, wy+off, wx+w+off, wy+bh+off], fill=lc)
    
    # Brick pattern
    for row in range(0, bh, 6):
        rgb = (max(0,walls[0]-35), max(0,walls[1]-25), max(0,walls[2]-15))
        draw.line([wx, wy+row, wx+w, wy+row], fill=rgb + (60,), width=1)
        for col in range(0, w, 10):
            off_x = 5 if (row // 6) % 2 == 0 else 0
            draw.line([wx+col+off_x, wy+row, wx+col+off_x, wy+row+6], fill=rgb + (60,), width=1)
    
    # Door with arch
    dw, dh = w//4, bh//2
    draw.rectangle([cx-dw//2, wy+bh-dh, cx+dw//2, wy+bh], fill=(55, 35, 15, 255))
    draw.rectangle([cx-dw//4, wy+bh-dh+2, cx+dw//4, wy+bh-2], fill=(80, 55, 30, 200))
    draw.arc([cx-dw//2, wy+bh-dh-4, cx+dw//2, wy+bh-dh+4], 0, 180, fill=(55, 35, 15, 255), width=3)
    
    # Windows with glow
    ww, wh = w//5, bh//4
    for side in [-1, 1]:
        wx2 = cx + side * w//4 - ww//2
        wy2 = wy + bh//4
        draw.rectangle([wx2, wy2, wx2+ww, wy2+wh], fill=(220, 200, 120, 240))
        draw.rectangle([wx2, wy2, wx2+ww, wy2+wh], outline=(50, 35, 15, 200), width=1)
        draw.line([wx2+ww//2, wy2, wx2+ww//2, wy2+wh], fill=(50, 35, 15, 180), width=1)
        draw.line([wx2, wy2+wh//2, wx2+ww, wy2+wh//2], fill=(50, 35, 15, 180), width=1)
        # Window glow
        draw.ellipse([wx2+ww//4, wy2+wh//4, wx2+ww*3//4, wy2+wh*3//4], fill=(255, 240, 180, 60))
    
    # Roof (3D with depth)
    rh = bh // 3
    rw = w + 16
    
    # Roof right side (darker)
    roof_side = (roof[0]//2, roof[1]//2, roof[2]//2, 255)
    draw.polygon([(cx, wy-rh), (cx+rw//2+4, wy), (cx, wy+4), (cx+rw//2+4, wy+4)], fill=roof_side)
    
    # Roof front
    draw.polygon([(cx-rw//2-4, wy), (cx, wy-rh), (cx+rw//2+4, wy), (cx, wy+4)], fill=roof)
    
    # Roof top highlight
    rhl = (min(255,roof[0]+30), min(255,roof[1]+30), min(255,roof[2]+30), 200)
    draw.polygon([(cx-rw//4, wy-rh//2), (cx, wy-rh), (cx+rw//4, wy-rh//2), (cx, wy-rh//2)], fill=rhl)
    
    # Roof tile lines
    for ry in range(4, rh, 5):
        f = ry / rh
        lx = int(cx - (rw//2) * (1 - f))
        rx = int(cx + (rw//2) * (1 - f))
        draw.line([lx, wy-ry, rx, wy-ry], fill=(roof[0]//2, roof[1]//2, roof[2]//2, 60), width=1)
    
    # Flag (castle only)
    if name == "castle":
        fx, fy = cx, wy - rh - 12
        draw.line([fx, fy, fx, fy+18], fill=(90, 70, 40, 255), width=2)
        draw.polygon([(fx, fy), (fx+14, fy+5), (fx, fy+10)], fill=(220, 40, 40, 255))
    
    return img

def create_resource_3d(name, size=64):
    """Create 3D-looking resource sprites (trees, gold, stone, deer)."""
    img = Image.new("RGBA", (size, size+10), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size//2, size//2 - 5
    
    if name == "tree":
        # Drop shadow
        for i in range(6, 0, -1):
            draw.ellipse([cx - size//3 - i, cy + size//5, cx + size//3 + i, cy + size//3 + i//2], fill=(0, 0, 0, 35-i*5))
        # Trunk with 3D shading
        for i in range(5):
            tc = (90 - i*8, 55 - i*5, 20 - i*3, 255) if i < 3 else (100-i*10, 65-i*8, 30-i*5, 255)
            draw.rectangle([cx - 3 + i, cy - 2, cx + 3 + i, cy + size//4], fill=tc)
        # Foliage as 3D spheres
        layers = [
            (cx, cy - 10, size//3 + 2, (30, 90, 30)),
            (cx - 6, cy - 6, size//3 - 2, (40, 110, 40)),
            (cx + 5, cy - 5, size//3 - 3, (35, 100, 35)),
            (cx - 3, cy - 14, size//4, (50, 130, 50)),
            (cx + 3, cy - 16, size//4 - 2, (45, 120, 45)),
        ]
        for lx, ly, r, lc in layers:
            for rr in range(r, 1, -2):
                bright = 0.7 + 0.3 * (1 - rr/r)
                c = (min(255,int(lc[0]*bright)), min(255,int(lc[1]*bright)), min(255,int(lc[2]*bright)), 220)
                draw.ellipse([lx - rr, ly - rr, lx + rr, ly + rr], fill=c)
        # Highlight
        draw.ellipse([cx - 3, cy - 18, cx + 2, cy - 12], fill=(120, 200, 80, 150))
    
    elif name == "gold":
        for i in range(5, 0, -1):
            draw.ellipse([cx - 12 - i, cy + 10 - i, cx + 12 + i, cy + 15], fill=(0, 0, 0, 20-i*3))
        for rr in range(12, 0, -2):
            bright = 0.6 + 0.4 * (1 - rr/12)
            c = (min(255,int(220*bright)), min(255,int(180*bright)), min(255,int(40*bright)), 255)
            y1 = cy - 8 + (12-rr)
            y2 = cy + 8 - (12-rr)
            if y1 >= y2: continue
            draw.ellipse([cx - rr, y1, cx + rr, y2], fill=c)
        draw.ellipse([cx - 3, cy - 5, cx + 2, cy + 2], fill=(255, 220, 80, 200))
        draw.ellipse([cx - 5, cy, cx + 5, cy + 6], fill=(255, 230, 150, 100))
    
    elif name == "stone":
        for i in range(4, 0, -1):
            draw.ellipse([cx - 14 - i, cy + 8 - i, cx + 14 + i, cy + 12], fill=(0, 0, 0, 25-i*5))
        for rr in range(14, 0, -2):
            bright = 0.6 + 0.4 * (1 - rr/14)
            c = (min(255,int(140*bright)), min(255,int(135*bright)), min(255,int(130*bright)), 255)
            y1 = cy - 6 + (14-rr)
            y2 = cy + 6 - (14-rr)
            if y1 >= y2: continue
            draw.ellipse([cx - rr, y1, cx + rr, y2], fill=c)
        draw.ellipse([cx - 3, cy - 3, cx + 2, cy + 2], fill=(180, 180, 175, 180))
    
    elif name == "deer":
        for i in range(4, 0, -1):
            draw.ellipse([cx - 10 - i, cy + 6 - i, cx + 10 + i, cy + 10], fill=(0, 0, 0, 25-i*5))
        # Body
        draw.ellipse([cx - 10, cy - 4, cx + 2, cy + 6], fill=(160, 100, 50, 255))
        draw.ellipse([cx - 8, cy - 2, cx, cy + 4], fill=(180, 120, 60, 200))
        # Head
        draw.ellipse([cx + 2, cy - 6, cx + 10, cy + 2], fill=(170, 110, 55, 255))
        # Legs
        for lx in [-6, -2, 2, 6]:
            draw.rectangle([cx + lx, cy + 4, cx + lx + 2, cy + 10], fill=(120, 70, 35, 255))
    
    return img

def generate_all():
    """Generate all game sprites."""
    configs = [
        ("hero", "player", (245, 175, 35), None, None, True, True),
        ("warrior", "player", (185, 105, 55), (165, 135, 105), (195, 195, 215), True, False),
        ("archer", "player", (85, 155, 85), (135, 105, 65), (165, 95, 35), False, False),
        ("cavalry", "player", (205, 135, 55), (155, 125, 85), (195, 195, 215), True, False),
        ("villager", "player", (155, 105, 75), (135, 115, 85), (165, 125, 65), False, False),
        ("artisan", "player", (185, 155, 55), (165, 145, 75), (215, 195, 65), False, False),
    ]
    buildings = ["castle", "barracks", "archery", "stable", "wall", "tower_arrow"]
    resources = ["tree", "gold", "stone", "deer"]
    
    print("Generating characters...")
    for name, team, bc, ac, wc, helm, hero in configs:
        img = create_unit(name, team, list(bc), list(ac) if ac else None, list(wc) if wc else None, helm, hero)
        img.save(os.path.join(SPRITE_DIR, f"{name}.png"))
        print(f"  ✅ {name}.png")
        img_e = create_unit(name, "enemy", list(bc), list(ac) if ac else None, list(wc) if wc else None, helm, False)
        img_e.save(os.path.join(SPRITE_DIR, f"enemy_{name}.png"))
        print(f"  ✅ enemy_{name}.png")
    
    print("\nGenerating buildings...")
    for b in buildings:
        img = create_building(b)
        img.save(os.path.join(SPRITE_DIR, f"building_{b}.png"))
        print(f"  ✅ building_{b}.png")
    
    print("\nGenerating 3D resources...")
    for r in resources:
        for v in range(3):
            img = create_resource_3d(r)
            fname = f"{r}_{v}.png" if r == "tree" else f"{r}.png"
            if r != "tree" and v > 0: continue
            img.save(os.path.join(SPRITE_DIR, fname))
            print(f"  ✅ {fname}")
    
    print(f"\nTotal: {len(os.listdir(SPRITE_DIR))} sprites")

if __name__ == "__main__":
    generate_all()
