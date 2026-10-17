from collections import deque
import sys

from PIL import Image, ImageFilter


source, destination = sys.argv[1:3]
image = Image.open(source).convert("RGB")
width, height = image.size
pixels = image.load()

# The generator sometimes paints a checkerboard instead of emitting alpha.
# Build a compact palette from the guaranteed-background outer border, then
# flood only matching pixels from that border so pale costume details survive.
border = []
for x in range(width):
    border.extend((pixels[x, 0], pixels[x, height - 1]))
for y in range(height):
    border.extend((pixels[0, y], pixels[width - 1, y]))
palette = list({tuple((channel // 8) * 8 for channel in color) for color in border})

def matches_background(color):
    return min(sum((color[i] - sample[i]) ** 2 for i in range(3)) for sample in palette) <= 52 ** 2

background = Image.new("L", image.size, 0)
mask = background.load()
queue = deque()
for x in range(width):
    queue.extend(((x, 0), (x, height - 1)))
for y in range(height):
    queue.extend(((0, y), (width - 1, y)))

while queue:
    x, y = queue.popleft()
    if mask[x, y] or not matches_background(pixels[x, y]):
        continue
    mask[x, y] = 255
    if x:
        queue.append((x - 1, y))
    if x + 1 < width:
        queue.append((x + 1, y))
    if y:
        queue.append((x, y - 1))
    if y + 1 < height:
        queue.append((x, y + 1))

background = background.filter(ImageFilter.GaussianBlur(0.8))
alpha = background.point(lambda value: 255 - value)
output = image.convert("RGBA")
output.putalpha(alpha)
output.save(destination)
