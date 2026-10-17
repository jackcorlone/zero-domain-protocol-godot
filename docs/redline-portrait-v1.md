# 赤线战术服立绘 · 完整状态 v1

状态：造型稿已生成并保存；透明背景未通过检查，未接入运行场景、未替换原立绘。

- 文件：`../assets/characters/lyra-redline-concept-v1.png`
- 规格：1024×1536 PNG，RGB，无Alpha通道。灰白方格为图片实际内容，不是查看器透明提示。
- 设计：沿用成年凌霁的脸、黑色高马尾、持剑站姿；以轻型黑色战术织物、小块白色护甲、红色线路替代原先厚重装甲，保留青色能源细节。
- 本张为完整状态，不包含另外两个破甲阶段，也未实现装备切换。
- 制作方式：内置 imagegen，未使用CLI/API fallback。
- 以现有 `assets/characters/lyra-portrait-2d-v1.png` 为参考。
- 初次生成及两次透明背景修正均未得到真正Alpha，故保留初次生成的造型稿；不把它当成已完成抠图的游戏素材。

## 生成提示词

Use case: identity-preserve.
Asset type: one transparent full-body 2D RPG alternate-costume portrait, intact stage.
Input image: edit target and strict identity, drawing-style, pose and framing reference.
Primary request: change ONLY this adult heroine's costume to the new "Redline" lightweight tactical suit. Preserve the same adult face, expression, long black high ponytail and bangs, body proportions, standing pose, hand placement, cyan energy blade, and entire head-to-boot composition. Keep her recognizable as exactly the same character.
Costume: a highly mobile sci-fi combat uniform, substantially LESS bulky and armored than the original. Matte charcoal-black opaque technical fabric covers torso, arms and legs; small ivory-white protective panels only at collarbone, outer forearms, knees and shins. Remove the heavy shoulder pauldrons, broad chest shell and bulky thigh plates. Slim flexible textile torso, articulated fabric joints, compact belt, practical flat combat boots. Fine crimson-red circuitry piping and small red limit-release indicator nodes make this variant distinctive; retain a few cyan power connectors to match her blade. Premium sleek engineered garment, not latex shine. Convey a glass-cannon build through reduced plate coverage, not exposed skin. This is brand-new INTACT clothing: no tears or damage yet.
Style: match the reference's 2D anime hand-painted illustration, ink contours, controlled cel shading. Not a 3D render.
Output: one portrait canvas, preferably same 1024x1536 dimensions and same character anchor as input. Full sword, hair and boots inside frame. Actual transparent RGBA PNG with alpha-zero background, including spaces between limbs and hair. No painted checkerboard, no solid backdrop, no grey halo, no floor or ground shadow, no captions or UI. Keep opaque clothing and white armor fully opaque.
Avoid: changing face, childlike proportions, new pose, lingerie, transparent fabric, nudity, sexual posing, extra characters, collage or multiple variants.

## 背景处理尝试（未通过）

Use case: background-extraction. Remove ONLY the baked grey-white checkerboard background from this image. Deliver the same adult anime sci-fi heroine as a genuinely transparent RGBA PNG cutout. Preserve her face, pose, black ponytail, entire intact black Redline tactical suit with fine red lines and white small armor panels, cyan sword, all hair and both boots. Retain original 1024x1536 canvas and subject scale and placement. Replace all background including the checkerboard between hair strands, arm and torso, sword and body, and between legs with true alpha zero. No painted checkerboard or solid backdrop. Do not repaint the heroine or add a glow halo, cast shadow, environment, captions or new objects. Keep white armor and face opaque. Actual alpha-channel transparency, not an illustration of transparency.

给这张角色图抠图。删除人物外的全部背景，只保留人物、头发、衣服、靴子和手里的光剑，输出带真实透明 alpha 通道的 PNG。不要画出代表透明的灰白格子，也不要白底。保持原图人物造型和站姿不变。

