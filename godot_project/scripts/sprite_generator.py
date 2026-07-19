#!/usr/bin/env python3
"""High-quality 256px sprite generator for Legado Muisca."""
from PIL import Image, ImageDraw, ImageFilter
import os

SIZE = 256
DIR = "assets/sprites"
os.makedirs(DIR, exist_ok=True)

def smooth_circle(draw, cx, cy, r, color):
    """Draw smooth circle with anti-aliasing."""
    draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=color)

def gradient_body(draw, cx, cy, w, h, top_color, bottom_color):
    """Draw a body with vertical gradient."""
    for y in range(h):
        t = y / h
        r = int(top_color[0] * (1-t) + bottom_color[0] * t)
        g = int(top_color[1] * (1-t) + bottom_color[1] * t)
        b = int(top_color[2] * (1-t) + bottom_color[2] * t)
        draw.rectangle([cx-w//2, cy-h//2+y, cx+w//2, cy-h//2+y+1], fill=(r,g,b,255))

def draw_character(draw, cx, cy, bc, unit_type, is_hero=False, is_enemy=False):
    """Draw a detailed character with shading."""
    s = SIZE // 64  # scale
    c = tuple(int(x*(0.5 if is_enemy else 1.0)) for x in bc)
    
    # Shadow
    for i in range(6,0,-1):
        a = 40 - i*6
        draw.ellipse([cx-20*s-i, cy+18*s, cx+20*s+i, cy+22*s], fill=(0,0,0,a))
    
    # Legs with gradient
    for leg_x in [-7, 7]:
        for y in range(14):
            t = y/14
            lc = (max(0,c[0]-30), max(0,c[1]-30), max(0,c[2]-30), 255)
            draw.rectangle([cx+leg_x*s-3, cy+4*s+y, cx+leg_x*s+2, cy+4*s+y+1], fill=lc)
    # Boots
    for bx in [-7, 5]:
        draw.rectangle([cx+bx*s-3, cy+15*s, cx+bx*s+3, cy+19*s], fill=(70,45,25,255))
    
    # Body gradient
    gradient_body(draw, cx, cy, 22, 16, (c[0]+20,c[1]+20,c[2]+20), c)
    
    # Arms
    arm_c = (max(0,c[0]-20), max(0,c[1]-20), max(0,c[2]-20), 255)
    draw.rectangle([cx-14*s, cy-6*s, cx-11*s, cy+4*s], fill=arm_c)
    draw.rectangle([cx+11*s, cy-6*s, cx+14*s, cy+4*s], fill=arm_c)
    
    # Weapon
    if unit_type == "warrior" or is_hero:
        wc = (255,220,50,255) if is_hero else (190,190,200,255)
        gw = 2; s2 = SIZE//64
        for wx in range(10):
            t = wx / 10
            wr = int(wc[0]*(1-t*0.3)); wg = int(wc[1]*(1-t*0.3)); wb = int(wc[2]*(1-t*0.3))
            draw.rectangle([cx+13*s+wx*s2, cy-14*s+wx*2, cx+14*s+wx*s2, cy+2*s], fill=(wr,wg,wb,255))
    elif unit_type == "archer":
        draw.arc([cx+12*s, cy-14*s, cx+26*s, cy+2*s], 260, 460, fill=(150,75,20,255), width=4)
    elif unit_type == "cavalry":
        draw.rectangle([cx+13*s, cy-16*s, cx+16*s, cy+2*s], fill=(185,185,195,255))
    elif unit_type == "villager":
        draw.rectangle([cx+13*s, cy-1*s, cx+18*s, cy+2*s], fill=(130,85,20,255))
    
    # Head with gradient
    head_c = (min(255,c[0]+25), min(255,c[1]+25), min(255,c[2]+25), 255)
    smooth_circle(draw, cx, cy-11*s, 8*s, head_c)
    
    # Eyes
    draw.ellipse([cx-5*s, cy-14*s, cx-1*s, cy-10*s], fill=(240,240,250,255))
    draw.ellipse([cx+1*s, cy-14*s, cx+5*s, cy-10*s], fill=(240,240,250,255))
    draw.ellipse([cx-3*s, cy-13*s, cx-2*s, cy-11*s], fill=(20,20,50,255))
    draw.ellipse([cx+2*s, cy-13*s, cx+4*s, cy-11*s], fill=(20,20,50,255))
    
    # Helmet/hat
    draw.rectangle([cx-7*s, cy-19*s, cx+7*s, cy-15*s], fill=(180,50,50,200))
    if is_hero:
        draw.ellipse([cx-4*s, cy-23*s, cx+4*s, cy-17*s], fill=(220,50,50,230))
        # Glow
        for r in range(24,30,2):
            draw.ellipse([cx-r*s, cy-r*s, cx+r*s, cy+r*s], outline=(255,220,50,15), width=2)

def create_character_sprite(name, body_color, unit_type="warrior", is_hero=False, is_enemy=False):
    img = Image.new("RGBA", (SIZE, SIZE), (0,0,0,0))
    draw_character(ImageDraw.Draw(img), SIZE//2, SIZE//2, body_color, unit_type, is_hero, is_enemy)
    return img

def create_building_sprite(name, w, h, wall_color, roof_color):
    img = Image.new("RGBA", (SIZE, SIZE), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    cx, cy = SIZE//2, SIZE//2 + 20
    pw, ph = SIZE//3, SIZE//3
    
    # Shadow
    for i in range(8,0,-1):
        draw.ellipse([cx-pw//2-i, cy+ph//2, cx+pw//2+i, cy+ph//2+8], fill=(0,0,0,30-i*3))
    
    # Wall with brick pattern
    draw.rectangle([cx-pw//2, cy-ph//2, cx+pw//2, cy+ph//2], fill=wall_color)
    for row in range(0, ph, 8):
        off = 5 if (row//8)%2==0 else 0
        draw.line([cx-pw//2, cy-ph//2+row, cx+pw//2, cy-ph//2+row], fill=(wall_color[0]//2,wall_color[1]//2,wall_color[2]//2,60), width=1)
        for col in range(off, pw, 16):
            draw.line([cx-pw//2+col, cy-ph//2+row, cx-pw//2+col, cy-ph//2+row+8], fill=(wall_color[0]//2,wall_color[1]//2,wall_color[2]//2,60), width=1)
    
    # Door
    dw, dh = pw//4, ph//2
    draw.rectangle([cx-dw//2, cy+ph//2-dh, cx+dw//2, cy+ph//2], fill=(55,40,25,255))
    
    # Roof with gradient
    rh = ph//3
    for ry in range(rh):
        t = ry/rh
        r = int(roof_color[0]*(1-t*0.5))
        g = int(roof_color[1]*(1-t*0.5))
        b = int(roof_color[2]*(1-t*0.5))
        lw = pw + 16 - t*20
        draw.rectangle([cx-int(lw//2), cy-ph//2-ry, cx+int(lw//2), cy-ph//2-ry+1], fill=(r,g,b,255))
    
    return img

def create_tree_sprite():
    img = Image.new("RGBA", (SIZE, SIZE), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    cx, cy = SIZE//2, SIZE//2 + 10
    
    # Shadow
    for i in range(5,0,-1): draw.ellipse([cx-30-i, cy+20, cx+30+i, cy+28], fill=(0,0,0,40-i*7))
    
    # Trunk gradient
    for y in range(20):
        t = y/20
        r, g, b = int(90+40*t), int(55+30*t), int(25+10*t)
        draw.rectangle([cx-4, cy+4+y, cx+4, cy+4+y+1], fill=(r,g,b,255))
    
    # Foliage layers
    colors = [(35,95,35),(45,110,40),(55,130,50),(60,145,55),(50,120,45)]
    radii = [35,28,22,16,10]
    offsets = [(0,5), (0,0), (0,-6), (0,-12), (0,-16)]
    for i, (lc, r) in enumerate(zip(colors, radii)):
        ox, oy = offsets[i]
        # Soft gradient foliage
        for fs in range(r, 0, -2):
            alpha = 200 + (r-fs)*2
            rc = (min(255,lc[0]+(r-fs)*2), min(255,lc[1]+(r-fs)), min(255,lc[2]+(r-fs)//2), min(255,alpha))
            draw.ellipse([cx+ox-fs, cy+oy-fs, cx+ox+fs, cy+oy+fs], fill=rc)
    
    return img

def generate_all():
    units = [
        ("hero", (245,175,35), "warrior", True, False),
        ("warrior", (180,100,50), "warrior", False, False),
        ("archer", (80,150,80), "archer", False, False),
        ("cavalry", (200,130,50), "cavalry", False, False),
        ("villager", (150,100,70), "villager", False, False),
        ("artisan", (180,150,50), "villager", False, False),
    ]
    buildings = [
        ("building_castle", (150,85,45), (170,50,50)),
        ("building_barracks", (160,95,50), (180,80,60)),
        ("building_archery", (130,85,45), (160,110,70)),
        ("building_stable", (150,100,50), (160,120,70)),
        ("building_wall", (120,100,70), (110,90,60)),
        ("building_tower", (135,85,45), (155,50,50)),
        ("building_house", (150,100,70), (160,130,80)),
        ("building_church", (140,110,80), (170,60,50)),
        ("building_market", (160,120,70), (150,140,80)),
        ("building_siege", (120,90,60), (140,100,70)),
        ("building_forge", (110,85,65), (130,110,80)),
        ("building_gate", (130,100,65), (140,95,60)),
    ]
    
    print("Generating characters...")
    for name, bc, ut, hero, en in units:
        img = create_character_sprite(name, bc, ut, hero, False)
        img.save(os.path.join(DIR, name+".png"))
        print(f"  {name}.png")
        imge = create_character_sprite("enemy_"+name, bc, ut, False, True)
        imge.save(os.path.join(DIR, "enemy_"+name+".png"))
        print(f"  enemy_{name}.png")
    
    print("\nGenerating buildings...")
    for name, wc, rc in buildings:
        img = create_building_sprite(name, SIZE, SIZE, wc, rc)
        img.save(os.path.join(DIR, name+".png"))
        print(f"  {name}.png")
    
    print("\nGenerating trees...")
    for v in range(4):
        img = create_tree_sprite()
        img.save(os.path.join(DIR, f"tree_{v}.png"))
        print(f"  tree_{v}.png")
    
    print(f"\nTotal: {len(os.listdir(DIR))} sprites in {DIR}/")

if __name__ == "__main__":
    generate_all()
