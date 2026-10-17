# 《零域协议》二维美术第一版

2026-08-30。参考用户提供的二维探索地图和大立绘回合制战斗的表现形式，保留科幻世界观；不是仙侠换皮，也没有创建三维人物模型。

## 本次接入

- 指挥中心、B7：正交俯视手绘地图，重新对齐终端、补给、电梯、中继的位置，并为主要家具设置二维碰撞。
- 凌霁：四方向、每方向四帧的小比例行走角色，帧显示高度约58像素；仍可斜向移动，斜向时使用上下朝向。无玩家脚底标记或姓名下标。
- 沈砚、Sentinel：独立透明人物/敌人图像，不再用大菱形代替人物。
- 战斗：左侧敌人、中央四项指令、右侧大幅凌霁立绘，左下HP/MP与战报；攻击使用位移反馈，受伤使用闪色反馈，暂未制作独立手绘攻击/受伤帧。
- 人物面板与主菜单同步使用新美术。界面设计尺寸1280×720，项目原有1600×900启动窗口配置保留。
- 终端调查、补给、中继两路线、战斗数值、回收和任务奖励逻辑保留，未新增本轮之外的技能/等级/宝箱系统。

这是可运行的第一版画风与比例调整。地图目前是整张二维背景加碰撞，不是已拆分的TileMap素材库；后续扩展迷宫需继续制作分块地图和前景遮挡。

## 新素材

全部为本轮生成，旧素材未覆盖。透明图已检查Alpha通道，实际引擎画面已截图验证。

| 用途 | 工程内路径 |
| --- | --- |
| 指挥中心 | `assets/environments/command-2d-v1.png` |
| B7探索 | `assets/environments/b7-map-2d-v1.png` |
| B7战斗背景 | `assets/environments/b7-battle-2d-v1.png` |
| 凌霁行走 | `assets/characters/lyra-walk-2d-v1.png` |
| 凌霁立绘 | `assets/characters/lyra-portrait-2d-v1.png` |
| 哨兵 | `assets/enemies/sentinel-2d-v1.png` |
| 沈砚 | `assets/npcs/commander-2d-v1.png` |

## 验证

在项目目录运行：

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_2d_presentation.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_silent_circuit.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_battle_flow.gd
```

分别输出 `PRESENTATION_2D_OK`、`SILENT_CIRCUIT_OK`、`BATTLE_FLOW_OK`。沙箱内额外出现系统证书访问错误及编辑器设置写入权限错误，不是游戏脚本错误；图形模式运行正常。

`tests/capture_2d_preview.gd` 必须在图形模式运行，会临时打开窗口并依次截图指挥中心、B7、战斗、技能后战斗和人物面板，保存到 `/private/tmp/zero-domain-2d-*.png` 后自动退出。不会写入玩家存档。

## 本轮生成提示词

### 指挥中心

Create a production 2D RPG exploration map background, landscape 16:9. A hand-painted anime/SNES-inspired science fiction space station command center, viewed from a fixed elevated TOP DOWN orthographic camera, vertical wall fronts and square floor tiles, no vanishing point and absolutely not a cinematic 3D render or isometric diamond. Soft illustrative painted shading with crisp outlines, desaturated mint teal, pale ivory walls, blue-grey floor tiles, small amber accents; bright and readable. Map fills canvas edge to edge. No characters, no text, no UI, no icons. Layout is a single rectangular command hall: upper wall consoles, a small rectangular blue holographic command desk at approximately 60% x 31% y with walkable floor just south of it at 62%,46%; small wall terminal at 45%,35% with access floor south at45%,44%; right-wall elevator doorway at83%,60%; low supply chest at49%,70%. Main central and lower-middle floor is broad open connected walkable floor. Outer walls and furniture stay toward edges. Avoid giant central table. Objects are small relative to room for 50px tall chibi characters at 1280x720. Furnishings small 16-bit RPG tile proportions but beautiful non-pixel handpainted finish. Upper-left area stays quiet for compact HUD, lower edge quiet. Add plants and warm utility details. Flat videogame map asset, no dramatic lighting, no bloom, no cast black vignette. Keep all tiles aligned horizontally and vertically.

### 凌霁行走图集

输入参考：旧版 `assets/characters/lyra-7-v4.png`，仅用于人物身份与装甲。

Create a game-ready 2D CHIBI walking sprite sheet from reference heroine identity and costume. Reference is identity only: redraw completely flat handpainted anime RPG sprite, not realistic and not 3D render. Black high ponytail, black undersuit, white sci-fi armor, cyan accents. Cute 2.5 heads tall proportions with oversized recognizable head, tiny boots. Transparent RGBA background genuine alpha, no shadows, no rings, no text, no grid lines. SQUARE canvas, EXACT 4 columns by 4 rows equal square cells. Every frame identical character height, aligned centered, feet at same baseline at 85% cell height, character occupies 70% cell height. Row 1 FOUR front-facing south views; row 2 FOUR facing screen left; row3 FOUR facing screen right; row4 FOUR back-facing north views. Each row column sequence: neutral idle, left-foot step, neutral passing, right-foot step. All 16 separate sprites fully inside their cells, generous transparent gutters. Camera slightly top down like classic tilemap RPG. Clean readable linework that reads clearly at 56px tall. Only this one heroine, no other objects.

### 凌霁大立绘

输入参考同上。第一张输出有烘焙的方格背景，未接入游戏；第二轮编辑获得实际透明图。

Use attached character ONLY for identity and costume design. Redraw her completely as a beautiful TWO DIMENSIONAL hand-painted anime JRPG character illustration, clean ink outlines and soft cel painted shading. NOT photorealistic, NOT 3D rendered. Adult female sci-fi heroine LYRA-7: long black high ponytail and bangs, determined expressive face, black undersuit with ivory white armor plates and small cyan lights. Dynamic elegant standing battle-ready pose turned three quarter toward LEFT, holding a short cyan energy blade down-left; full body, boots entirely visible, sword and ponytail entirely in frame. Preserve futuristic armored identity; no fantasy robe. Transparent RGBA PNG background with genuine alpha, no ground shadow, no backdrop, no text, no labels, no border, no floor. Portrait 2:3 aspect ratio with 5% clear margins. Art is for large right-hand battle portrait in a classic illustrated 2D RPG.

最终编辑提示：

Remove the checkerboard BACKGROUND completely. It is erroneously painted into the input. Deliver the exact same illustrated heroine as a cutout on a genuinely transparent alpha-channel PNG. All grey and white squares outside silhouette must become alpha zero including between sword, arms and body and ponytail strands. Preserve all white armor, face, hair and cyan sword. Do not draw any checkerboard, white backdrop or shadow. Keep pose, original composition and complete boots. Actual transparent background, not a picture representing transparency.

### B7探索地图

输入参考：本轮指挥中心背景，仅用于统一投影与画风。

Create a second map for SAME 2D handpainted orthographic top-down sci-fi RPG. Use input only as art style and projection reference, not exact layout. Landscape16:9. B7 quarantine maintenance room, pale grey blue square tile floor, thick ivory teal outer walls, ominous muted rust accents and sparse amber warning lights; well lit and readable, no black cinematic shadows. Large open connected central floor, machinery concentrated at edges. LOWER LEFT wall elevator doorway with walkable entrance at15% x77% y. Broken relay terminal at43%x45%y, small footprint roughly7% canvas width and12%height. Three containment pods along top wall, server racks on right wall. Open encounter area at70%x55%y. Occasional cracked floor tiles, two loose cables close to wall, 2D illustrated texture. No characters, no monsters, no UI, no text, no labels. Top down axis-aligned squared tiles, NO vanishing point or isometric diamond. Calm lower edge for HUD. Flat painted game map, not 3D render.

### B7战斗背景

Landscape16:9 hand-painted 2D anime JRPG battle BACKGROUND ONLY. Sci-fi quarantine room interior, blue-grey industrial floor in lower half, pale ivory teal containment pods and wall conduits in upper half. Eye-level side-view stage with very gentle illustrative depth, like a classic 2D turn-based RPG background illustration. Broad empty stage on left for one robot enemy, quiet right half behind large hero portrait. Soft painterly cel shading and ink outlines, readable teal slate ivory colors with small amber alert lights, bright enough to see clearly, no black vignette. No characters or robots or text or UI. Not a photorealistic render. Beautiful cohesive illustrated environment for sci-fi heroine.

### Sentinel

Single full body sci-fi sentinel robot enemy, facing three-quarter toward screen RIGHT, for a handpainted 2D anime RPG battle. Chunky rounded ivory white armor, grey mechanical joints, compact legs and powerful forearms, single horizontal amber visor, teal chest reactor. Simple distinctive silhouette, slightly exaggerated 3 heads tall robot proportions. Bold clean ink outlines, softly painted cel shading, NOT realistic 3D rendering. Complete full body isolated in center with all limbs visible, feet fully in canvas and 8% margin. Square canvas, genuinely transparent PNG alpha background. No ground, no shadow, no text, no symbols, no checkerboard. Suitable both large battle enemy and small map sprite.

### 沈砚

A single small 2D chibi RPG NPC character sprite on actual transparent RGBA background. Mature male space-station commander, short neat dark grey hair, dark teal military uniform with ivory shoulder armor and subtle gold rank trim, boots. Front facing with slightly top-down view. 2.5 heads tall, clean ink outlines soft painted anime shading, flat illustrated 2D not realistic3D. Idle standing pose, full body with clear silhouette and8% transparent margin, centered in square canvas. No floor or shadow, no text, no checkerboard.
