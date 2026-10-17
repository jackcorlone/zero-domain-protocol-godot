# 凌霁日常美术交付记录

2026-09-04。仅素材与设计交付；未运行测试，未启动 Godot，未接入卧室碰撞或角色换装功能。

| 文件 | 用途与限制 |
| --- | --- |
| `assets/characters/lyra-daily-portrait-v1.png` | 实色背景全身睡衣造型稿；不是透明立绘 |
| `assets/characters/lyra-daily-chibi-sheet-v1.png` | 2×2 正、背、左、右静态造型稿；不是行走动画，需后续切图、抠图和统一脚底锚点 |
| `assets/characters/lyra-daily-expressions-v1.png` | 3×2 平静、微笑、思考、惊讶、警惕、坚定头像；尚未绑定对话表情 |
| `assets/environments/lyra-bedroom-map-v1.png` | 科幻卧室背景；没有碰撞、遮挡、门禁或交互点代码 |

设计与后续算法解谜方向见 [日常设计](lyra-daily-design.md)。本批不修改技能和战斗数值。

## 生成过程与完整提示词

生成工具：内置 imagegen。保留原始输出。两次透明背景尝试得到绘制的棋盘格而非有效透明通道，未作为成品；最终改为实色背景造型稿。不能把透明处理标为已完成。

### daily

```text
Use case: identity-preserve. Asset type: full-body transparent 2D RPG daily costume portrait. Reference is identity reference for adult heroine Ling Ji, preserve adult face, dark eyes, black hair and recognisable high ponytail; this is an off-duty costume variant, not a new person. Replace combat armor with comfortable modest lounge pajamas: loose slate-blue long-sleeve crewneck shirt, pale ivory seam piping, loose ankle-length trousers and soft indoor slippers, tiny cyan wrist comm. Opaque fabric, practical relaxed fit, no cleavage, no sheer material, no lingerie, no exposed midriff. Calm alert expression, relaxed upright standing posture, one hand holding a small plain mug down at waist, other arm relaxed. Clean hand-inked 2D anime JRPG illustration matching the reference rendering, not photorealistic or 3D. Single full body with all hair, fingers and slippers intact, central portrait canvas 2:3, 8 percent clear margins. True transparent RGBA background, no room, floor, shadow, painted checkerboard, caption, UI or logos. This is a reusable ordinary daily character portrait.
```

### bedroom

```text
Use case: stylized-concept. Asset type: playable-looking TOP-DOWN 2D RPG sci-fi bedroom background map, environment only, 16:9 landscape. Personal quarters for adult armored heroine Ling Ji in SITE OMEGA base. Quiet warm ivory and slate-blue interior with subtle cyan technology accents matching a hand-painted 2D anime RPG. Orthographic elevated top-down RPG camera, straight parallel room edges, flat WALKABLE FLOOR across the center and lower half, NOT eye-level interior photography, NOT dramatic perspective. Single room: narrow neatly made bed along upper-left wall with navy duvet, bedside lamp, secure storage wardrobe upper-right, compact writing/data desk on upper wall, a small armor charging rack near right wall holding white armor components only, reading chair left side, small plant. Main door centered on bottom wall with interior privacy lock panel. Clearly distinguish walls/furniture from broad empty floor; no furniture blocking route between bed, desk, wardrobe and door. Cozy private SAFE space, no cameras or observers, no people, no text, no labels, no UI, no watermark. Do not add any readable terminal text. This is one complete background illustration; collision and interactions added later by the game.
```

### daily_cutout

```text
Use case: background-extraction. EDIT TARGET is the attached adult Ling Ji lounge-clothes portrait. Preserve EXACT character identity, posture, hair, mug, loose slate-blue full-length pajamas, slippers, face and 1024x1536 portrait framing. CHANGE ONLY BACKGROUND. Remove the entire painted grey-and-white checkerboard including gaps between hair strands and between limbs. Output genuine transparent PNG RGBA with alpha zero outside character. No checkerboard pixels, no grey/white solid background, no floor or cast shadow. Keep clothing and character opaque with crisp clean edges. Do not restyle or redraw costume.
```

### chibi

```text
Use case: stylized-concept. Attached image is character/costume identity reference ONLY, NOT background. Create a 2D RPG CHIBI TURNAROUND DESIGN SHEET of the same ADULT heroine Ling Ji in loose slate-blue long-sleeve pajamas, ivory seam piping, long pants, slippers, black high ponytail. Four equally sized cells on a regular 2 by 2 grid: top-left front facing, top-right back facing, bottom-left left side, bottom-right right side. Each full body visible, aligned feet and consistent 3.5-head-tall adult stylized proportions across cells, no mug to keep idle silhouette clear. Small readable clean outlines and simple cel shading, anime RPG character design, not photorealistic. Quiet solid pale blue-grey background, NO painted checkerboard, no decorative frames, no text, no numbers or labels. All four figures separated with clear margins. This is four STATIC direction poses, not a walking animation.
```

### expressions

```text
Use case: identity-preserve. Attached image is identity reference ONLY. Create a uniform 3 columns by 2 rows expression ICON ATLAS for adult heroine Ling Ji in slate-blue crewneck lounge shirt and black high ponytail. All six cells are exactly equally sized, each a consistent head-and-shoulders portrait at identical scale and centered face anchor, same hair and clothing. Reading order: calm neutral; warm small smile; thoughtful with slightly lowered brows; surprised with eyes widened; wary/skeptical; determined confident. Clean 2D anime RPG line art and cel shading. Each face completely inside its cell with 10 percent margins, no hair crossing into adjacent cells. Flat solid deep slate-blue background in all cells, no borders, no gaps, no text, no numbers, no icons, no speech bubbles, no checkerboard. Landscape 3:2 sheet intended for equal grid cropping. Preserve adult identity; not infant faces or romantic expressions.
```

### daily_solid

```text
Use case: precise-object-edit. Edit the attached Ling Ji daily pajama portrait. Preserve character identity, hair, loose slate-blue long-sleeve pajamas, ivory piping, mug, slippers and full-body upright pose. Replace ALL checkerboard background pixels with ONE completely smooth solid desaturated blue-grey background (#263949). Do not request or draw transparency: this deliverable is an OPAQUE character design portrait on a solid studio backdrop. No checkerboard anywhere including gaps in hair and between limbs. No gradients, no room, no floor line, no captions or logos. Clean 2D anime RPG full-body character presentation, entire ponytail and slippers visible, 1024x1536 portrait.
```

## 原始输出

### initial

Generated images are saved to /Users/xuzhe/.codex/generated_images/01a0502b-6c32-7050-b773-7a2d7f69aa69 as /Users/xuzhe/.codex/generated_images/01a0502b-6c32-7050-b773-7a2d7f69aa69/exec-a5373a74-2d34-4a99-9bff-abed78496001.png by default.
If you need to use a generated image at another path, copy it and leave the original in place unless the user explicitly asks you to delete it.
The generated image is already displayed to the user. There is no need to render it in the final response as a Markdown image or file link.

### bedroom

Generated images are saved to /Users/xuzhe/.codex/generated_images/01a0502b-6c32-7050-b773-7a2d7f69aa69 as /Users/xuzhe/.codex/generated_images/01a0502b-6c32-7050-b773-7a2d7f69aa69/exec-ca0d826f-c536-4743-8000-76f4f388d08f.png by default.
If you need to use a generated image at another path, copy it and leave the original in place unless the user explicitly asks you to delete it.
The generated image is already displayed to the user. There is no need to render it in the final response as a Markdown image or file link.

### rejected_cutout

Generated images are saved to /Users/xuzhe/.codex/generated_images/01a0502b-6c32-7050-b773-7a2d7f69aa69 as /Users/xuzhe/.codex/generated_images/01a0502b-6c32-7050-b773-7a2d7f69aa69/exec-aa649ff8-5e4b-481b-81e1-31a42381f9f6.png by default.
If you need to use a generated image at another path, copy it and leave the original in place unless the user explicitly asks you to delete it.
The generated image is already displayed to the user. There is no need to render it in the final response as a Markdown image or file link.

### chibi

Generated images are saved to /Users/xuzhe/.codex/generated_images/01a0502b-6c32-7050-b773-7a2d7f69aa69 as /Users/xuzhe/.codex/generated_images/01a0502b-6c32-7050-b773-7a2d7f69aa69/exec-14c55699-65c0-49a4-bcae-4edc6d564dcd.png by default.
If you need to use a generated image at another path, copy it and leave the original in place unless the user explicitly asks you to delete it.
The generated image is already displayed to the user. There is no need to render it in the final response as a Markdown image or file link.

### expressions

Generated images are saved to /Users/xuzhe/.codex/generated_images/01a0502b-6c32-7050-b773-7a2d7f69aa69 as /Users/xuzhe/.codex/generated_images/01a0502b-6c32-7050-b773-7a2d7f69aa69/exec-28164089-de5f-4b8c-ad40-97faf1c61aaa.png by default.
If you need to use a generated image at another path, copy it and leave the original in place unless the user explicitly asks you to delete it.
The generated image is already displayed to the user. There is no need to render it in the final response as a Markdown image or file link.

### final_portrait

Generated images are saved to /Users/xuzhe/.codex/generated_images/01a0502b-6c32-7050-b773-7a2d7f69aa69 as /Users/xuzhe/.codex/generated_images/01a0502b-6c32-7050-b773-7a2d7f69aa69/exec-e196b0d4-8c8d-4fb1-8774-162735737065.png by default.
If you need to use a generated image at another path, copy it and leave the original in place unless the user explicitly asks you to delete it.
The generated image is already displayed to the user. There is no need to render it in the final response as a Markdown image or file link.


