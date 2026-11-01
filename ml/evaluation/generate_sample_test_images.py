"""CropGuard AI: Sample Test Image Generator

Generates high-resolution synthetic leaf and pest sample images for offline
and demonstration testing across the 4 supported agricultural crops:
1. Paddy/Rice (Brown Planthopper)
2. Cotton (Aphids)
3. Tomato (Helicoverpa armigera)
4. Chilli (Thrips)
"""

import os
from PIL import Image, ImageDraw, ImageFilter


def create_sample_leaf(crop_name: str, pest_name: str, output_path: str):
    width, height = 640, 640
    # Base background: agricultural soil/field color
    img = Image.new("RGB", (width, height), color=(40, 32, 24))
    draw = ImageDraw.Draw(img)

    # Draw natural leaf foliage according to crop
    if crop_name == "Paddy/Rice":
        # Slender green rice blade
        draw.polygon([(100, 600), (320, 40), (540, 600)], fill=(76, 175, 80))
        draw.line([(320, 40), (320, 600)], fill=(129, 199, 132), width=4)
        # Pest cluster (Brown Planthoppers near base)
        for offset in [(-30, 420), (20, 440), (-10, 470), (25, 500)]:
            x, y = 320 + offset[0], offset[1]
            draw.ellipse([x - 12, y - 20, x + 12, y + 20], fill=(139, 69, 19), outline=(90, 40, 10))
            draw.line([(x - 15, y), (x + 15, y)], fill=(60, 30, 5), width=2)
    elif crop_name == "Cotton":
        # Broad palmate cotton leaf
        draw.ellipse([120, 100, 520, 560], fill=(46, 125, 74))
        # Vein network
        draw.line([(320, 100), (320, 560)], fill=(102, 187, 106), width=5)
        draw.line([(320, 330), (160, 220)], fill=(102, 187, 106), width=3)
        draw.line([(320, 330), (480, 220)], fill=(102, 187, 106), width=3)
        # Aphid clusters (yellowish-green nymphs)
        for offset in [(-60, 280), (-40, 300), (-70, 320), (50, 270), (70, 300)]:
            x, y = 320 + offset[0], offset[1]
            draw.ellipse([x - 8, y - 10, x + 8, y + 10], fill=(205, 220, 57), outline=(139, 195, 74))
    elif crop_name == "Tomato":
        # Serrated compound tomato foliage with fruit
        draw.ellipse([140, 120, 500, 540], fill=(56, 142, 60))
        # Tomato fruit
        draw.ellipse([260, 340, 420, 500], fill=(229, 57, 53), outline=(183, 28, 28))
        # Fruit borer (Helicoverpa armigera caterpillar bore hole)
        draw.ellipse([330, 390, 370, 430], fill=(62, 39, 35)) # Bore hole
        draw.arc([300, 370, 400, 450], start=30, end=200, fill=(100, 120, 40), width=10) # Caterpillar body
    elif crop_name == "Chilli":
        # Lanceolate smooth chilli leaf
        draw.polygon([(320, 60), (480, 320), (320, 580), (160, 320)], fill=(46, 125, 50))
        draw.line([(320, 60), (320, 580)], fill=(129, 199, 132), width=3)
        # Thrips (tiny slender black/yellow insects)
        for offset in [(-30, 220), (20, 260), (-15, 300), (35, 340)]:
            x, y = 320 + offset[0], offset[1]
            draw.rectangle([x - 4, y - 12, x + 4, y + 12], fill=(33, 33, 33), outline=(66, 66, 66))

    # Apply slight smoothing for natural photography look
    img = img.filter(ImageFilter.SMOOTH_MORE)
    img.save(output_path, "JPEG", quality=95)
    print(f"Generated sample image for {crop_name} -> {output_path}")


def main():
    sample_dir = os.path.join(os.path.dirname(__file__), "..", "sample_images")
    os.makedirs(sample_dir, exist_ok=True)

    samples = [
        ("Paddy/Rice", "Brown Planthopper", os.path.join(sample_dir, "rice_brown_planthopper.jpg")),
        ("Cotton", "Aphids", os.path.join(sample_dir, "cotton_aphids.jpg")),
        ("Tomato", "Helicoverpa armigera", os.path.join(sample_dir, "tomato_helicoverpa.jpg")),
        ("Chilli", "Thrips", os.path.join(sample_dir, "chilli_thrips.jpg")),
    ]

    for crop, pest, path in samples:
        create_sample_leaf(crop, pest, path)


if __name__ == "__main__":
    main()
