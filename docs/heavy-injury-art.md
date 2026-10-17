# 黑白重甲 · 受伤战损预览

2026-08-30。使用 imagegen 技能和内置图像编辑工具（非 CLI）。已按用户最新要求加入四肢露肤破口、红色擦伤和少量血痕，保留原成年角色、站姿、黑白重甲与青色武器。不是仅在甲面涂擦痕。

## 状态与文件

- 破损预览：[lyra-heavy-injury-stage1-concept-v1.png](../assets/characters/lyra-heavy-injury-stage1-concept-v1.png)。原始生成：`exec-9bece685-1c4d-486d-afc1-e1af979a4ecd.png`。
- 解限预览：[lyra-heavy-injury-stage2-concept-v1.png](../assets/characters/lyra-heavy-injury-stage2-concept-v1.png)。原始生成：`exec-10423c48-8884-4aee-8a0d-b60a6e7e2c2c.png`。
- 原始目录：`/Users/xuzhe/.codex/generated_images/01a01f80-5d29-7392-82cd-566fa808ad79/`。
- 两图都是1024×1536 RGB PNG，sips 检测 `hasAlpha: no`。格子背景被画进图片，不是真透明。
- 单独向生成器请求背景提取后，结果 `exec-1e3a2ada-ac49-42d1-9f40-3398666d2de8.png`、`exec-b5590c95-576f-4eb7-862f-df06d3743d04.png` 仍无alpha；未采用。
- 因此暂未写入自动加载的 `lyra-heavy-stage-1-v1.png` / `lyra-heavy-stage-2-v1.png` 路径，游戏继续用原图并提示战损图待补。已请求用户授权本地抠图，尚未执行。
- 本轮未遇到额度不足；透明提取失败是输出质量问题，不是额度问题，不能据此推测剩余额度。

## 视觉分级

正常态沿用原图；一阶段以手臂、小腿局部破口和少量血痕为主；二阶段增加大腿外侧和小腿的受损范围。胸腹和骨盆仍保持遮蔽，无深部创口。按用户最新要求：HP ≥50% 为正常，25% ≤ HP <50% 为一阶段，0 < HP <25% 为二阶段。50%/25% 本身不触发更重阶段；回血跨阈值会恢复。沿用各阶段原有速度与承伤倍率，不改变倍率数值。透明背景仍待处理，切换规则已改，但运行时仍回退完整图。

## 完整提示词记录

### 阶段 1

初版编辑目标：`assets/characters/lyra-portrait-2d-v1.png`。

```text
Use case: identity-preserve. Image 1 is the EDIT TARGET, the existing adult heroine Ling Ji in black and ivory-white sci-fi heavy armor. Create a battle-damage variant for the same 2D RPG portrait. Lock identity, face, expression, high black ponytail, proportions, sword, exact standing pose, hands, boots and full-body framing to image 1. Keep the inked anime illustration style, same lighting and cyan energy accents. Keep the fully opaque black high-neck undersuit completely covering torso, hips and legs. Only change the condition of external armor and equipment, not anatomy. Stage 1 DAMAGED: obvious fractures and dark impact scratches across the ivory shoulder and forearm plates, chipped white thigh plate edges, frayed outer utility straps, small scuffs and torn external fabric at knees with the opaque inner suit underneath intact. Keep all major armor plates attached and recognizable. Damage should be clearly visible at game portrait scale. No blood, no wounds, no nudity. Genuinely transparent alpha background, no grey or black backdrop, no glow cloud, no floor shadow, no text, no checkerboard. Full body and sword tip within frame, same portrait canvas 1024x1536.
```

受伤修订编辑目标：`exec-763a46f2-54b5-439b-8b3d-4183868be69d.png`。

```text
Use case: identity-preserve. Image 1 is the edit target, an adult armored sci-fi heroine. Preserve exact face, adult identity, black ponytail, body proportions, pose, energy sword, ivory/black armor design and 2D inked painted style. User requests readable non-graphic combat injury rather than only surface scratches. Keep chest, abdomen, hips and pelvis fully covered in opaque armor/undersuit; no sexual framing. Full body, feet and sword tip intact. CRITICAL remove the painted checkerboard completely: deliver actual transparent alpha outside the character, not a white/grey checker pattern painted as pixels, no opaque backdrop, no floor or drop shadow. Medium damage: the external armor cracks remain. Add torn black fabric and broken armor edges at one forearm and one shin/calf, exposing small patches of natural skin. On exposed skin show superficial red abrasions, a few restrained dark red dried blood smears, a thin red scrape on a cheek. No deep wounds, no gore, no dripping blood. Deliberate battle wear, not fashion cutouts. Preserve original pose and silhouette. Transparent PNG portrait 1024x1536.
```

### 阶段 2

初版编辑目标：`assets/characters/lyra-portrait-2d-v1.png`。

```text
Use case: identity-preserve. Image 1 is the EDIT TARGET, the existing adult heroine Ling Ji in black and ivory-white sci-fi heavy armor. Create a battle-damage variant for the same 2D RPG portrait. Lock identity, face, expression, high black ponytail, proportions, sword, exact standing pose, hands, boots and full-body framing to image 1. Keep the inked anime illustration style, same lighting and cyan energy accents. Keep the fully opaque black high-neck undersuit completely covering torso, hips and legs. Only change the condition of external armor and equipment, not anatomy. Stage 2 LIMIT RELEASE: visibly severe outer armor damage, one outer shoulder pauldron partly broken away, segmented forearm shell split, an outer thigh plate partly missing, fractured shin shell and damaged belt hardware. Expose mechanical joints and a few cyan power cables under the OUTER armor, but the opaque black inner suit stays fully intact and covered. Preserve the central white chest armor with strong cracks and missing small edge pieces, keep the heroine composed and battle-ready. A few tiny cyan electrical sparks near damaged mechanisms, no detached floating debris. More damaged than minor scuffs, unmistakably the same original outfit. No blood, no wounds, no nudity. Genuinely transparent alpha background, no grey or black backdrop, no glow cloud, no floor shadow, no text, no checkerboard. Full body and sword tip within frame, same portrait canvas 1024x1536.
```

受伤修订编辑目标：`exec-db517c55-0bad-4ff3-8dde-265c5389eaed.png`。

```text
Use case: identity-preserve. Image 1 is the edit target, an adult armored sci-fi heroine. Preserve exact face, adult identity, black ponytail, body proportions, pose, energy sword, ivory/black armor design and 2D inked painted style. User requests readable non-graphic combat injury rather than only surface scratches. Keep chest, abdomen, hips and pelvis fully covered in opaque armor/undersuit; no sexual framing. Full body, feet and sword tip intact. CRITICAL remove the painted checkerboard completely: deliver actual transparent alpha outside the character, not a white/grey checker pattern painted as pixels, no opaque backdrop, no floor or drop shadow. Heavy damage: keep the broken external shoulder, forearm and thigh armor and cyan mechanisms. Add obvious irregular tears in the outer-arm sleeve, the outer thigh fabric (well below the hip), and calf fabric, revealing limited patches of bare skin with superficial red scrapes and a few small blood streaks. Blood is restrained but clearly visible on skin and nearby torn fabric; make damage more extensive than the medium stage. No deep wound anatomy, no gore, no exposed organs, no pools or gushes of blood. Central torso and hip armor intact and fully opaque. Preserve original pose and silhouette. Transparent PNG portrait 1024x1536.
```

### 透明提取尝试（未通过）

```text
Use case: background-extraction. Remove the entire white and grey CHECKERBOARD BACKGROUND from this image. The checkerboard is currently baked into the pixels and must NOT appear in the output. Return an RGBA PNG cutout with actual alpha=0 transparency everywhere outside the woman, including holes between legs, arms and strands of hair. Preserve the entire illustrated adult woman, her face, pose, proportions, armor, small superficial blood smears, sword and cyan cables exactly. Do not repaint the character. No checkerboard, no white background, no grey background, no shadows, no decorative backdrop. This is a technical transparent-background extraction task, not another concept drawing.
```
