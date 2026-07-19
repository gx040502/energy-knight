import os
from PIL import Image, ImageDraw

def create_dir_if_not_exists(path):
    if not os.path.exists(path):
        os.makedirs(path)

def generate_sprites():
    base_dir = r"c:\Users\User\Desktop\godot projects\energy-knight\JunZhi\sprites"
    create_dir_if_not_exists(base_dir)

    # Helper to create a new transparent image
    def new_img(w, h):
        return Image.new("RGBA", (w, h), (0, 0, 0, 0))

    # Helper to draw a pixelated rectangle
    def draw_rect(draw, x0, y0, x1, y1, color):
        draw.rectangle([x0, y0, x1, y1], fill=color)

    # 1. SCOUT SPRITES (32x32)
    colors_scout = {
        "body": (34, 197, 94, 255),    # Green
        "vest": (120, 53, 15, 255),    # Brown
        "eyes": (239, 68, 68, 255),    # Red
        "weapon": (156, 163, 175, 255) # Silver
    }
    for i in range(4):
        # Idle (breathing up and down)
        img = new_img(32, 32)
        draw = ImageDraw.Draw(img)
        offset = i % 2
        
        # Legs
        draw_rect(draw, 12, 26, 14, 29, (0, 0, 0, 255))
        draw_rect(draw, 18, 26, 20, 29, (0, 0, 0, 255))
        # Body/Vest
        draw_rect(draw, 10, 14 - offset, 22, 25 - offset, colors_scout["vest"])
        draw_rect(draw, 12, 16 - offset, 20, 23 - offset, colors_scout["body"])
        # Head
        draw_rect(draw, 11, 6 - offset, 21, 13 - offset, colors_scout["body"])
        # Eyes
        draw_rect(draw, 13, 9 - offset, 14, 10 - offset, colors_scout["eyes"])
        draw_rect(draw, 18, 9 - offset, 19, 10 - offset, colors_scout["eyes"])
        # Sword
        draw_rect(draw, 23, 12 - offset, 25, 20 - offset, colors_scout["weapon"])
        
        img.save(os.path.join(base_dir, f"scout_idle{i+1}.png"))

        # Walk (legs swinging)
        img = new_img(32, 32)
        draw = ImageDraw.Draw(img)
        # Legs swing
        if i % 2 == 0:
            draw_rect(draw, 10, 26, 12, 29, (0, 0, 0, 255))
            draw_rect(draw, 20, 26, 22, 29, (0, 0, 0, 255))
        else:
            draw_rect(draw, 13, 26, 15, 29, (0, 0, 0, 255))
            draw_rect(draw, 17, 26, 19, 29, (0, 0, 0, 255))
        # Body/Vest
        draw_rect(draw, 10, 14, 22, 25, colors_scout["vest"])
        draw_rect(draw, 12, 16, 20, 23, colors_scout["body"])
        # Head
        draw_rect(draw, 11, 6, 21, 13, colors_scout["body"])
        # Eyes
        draw_rect(draw, 13, 9, 14, 10, colors_scout["eyes"])
        draw_rect(draw, 18, 9, 19, 10, colors_scout["eyes"])
        # Sword
        draw_rect(draw, 23, 14, 25, 22, colors_scout["weapon"])

        img.save(os.path.join(base_dir, f"scout_walk{i+1}.png"))

    # 2. KNOCKBACK SCOUT SPRITES (32x32)
    colors_kb = {
        "body": (22, 101, 52, 255),    # Dark Green
        "vest": (69, 26, 3, 255),      # Dark Brown
        "eyes": (234, 179, 8, 255),    # Yellow
        "club": (146, 64, 14, 255)     # Orange-Brown Club
    }
    for i in range(4):
        # Idle
        img = new_img(32, 32)
        draw = ImageDraw.Draw(img)
        offset = i % 2
        
        # Legs
        draw_rect(draw, 12, 26, 14, 29, (0, 0, 0, 255))
        draw_rect(draw, 18, 26, 20, 29, (0, 0, 0, 255))
        # Body
        draw_rect(draw, 10, 14 - offset, 22, 25 - offset, colors_kb["vest"])
        draw_rect(draw, 12, 16 - offset, 20, 23 - offset, colors_kb["body"])
        # Head
        draw_rect(draw, 11, 6 - offset, 21, 13 - offset, colors_kb["body"])
        # Eyes
        draw_rect(draw, 13, 9 - offset, 14, 10 - offset, colors_kb["eyes"])
        draw_rect(draw, 18, 9 - offset, 19, 10 - offset, colors_kb["eyes"])
        # Giant Club
        draw_rect(draw, 23, 10 - offset, 27, 24 - offset, colors_kb["club"])
        
        img.save(os.path.join(base_dir, f"kb_scout_idle{i+1}.png"))

        # Walk
        img = new_img(32, 32)
        draw = ImageDraw.Draw(img)
        if i % 2 == 0:
            draw_rect(draw, 10, 26, 12, 29, (0, 0, 0, 255))
            draw_rect(draw, 20, 26, 22, 29, (0, 0, 0, 255))
        else:
            draw_rect(draw, 13, 26, 15, 29, (0, 0, 0, 255))
            draw_rect(draw, 17, 26, 19, 29, (0, 0, 0, 255))
        # Body
        draw_rect(draw, 10, 14, 22, 25, colors_kb["vest"])
        draw_rect(draw, 12, 16, 20, 23, colors_kb["body"])
        # Head
        draw_rect(draw, 11, 6, 21, 13, colors_kb["body"])
        # Eyes
        draw_rect(draw, 13, 9, 14, 10, colors_kb["eyes"])
        draw_rect(draw, 18, 9, 19, 10, colors_kb["eyes"])
        # Giant Club
        draw_rect(draw, 23, 12, 27, 26, colors_kb["club"])

        img.save(os.path.join(base_dir, f"kb_scout_walk{i+1}.png"))

    print("Successfully generated Milestone 1 sprite frames!")

if __name__ == "__main__":
    generate_sprites()
