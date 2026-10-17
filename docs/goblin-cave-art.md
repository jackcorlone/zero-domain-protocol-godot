# 哥布林洞穴：首轮场景与怪物美术设计

状态：已生成两张场景图和两张透明背景怪物图；尚未接入 Godot 场景、碰撞、事件与战斗数据。

## 资产

| 类型 | 名称 | 文件 | 尺寸 | 透明通道 |
|---|---|---|---:|---|
| 场景 | 菌灯洞窟 | `assets/environments/goblin-cave-entrance-v1.png` | 1536×1024 | 否（背景图） |
| 场景 | 赤晶祭坛 | `assets/environments/goblin-cave-depths-v1.png` | 1536×1024 | 否（背景图） |
| 怪物 | 巨型哥布林「岩背」 | `assets/enemies/giant-goblin-v1.png` | 1247×1261 | 是 |
| 怪物 | 哥布林祭祀「幽孢祷者」 | `assets/enemies/goblin-shaman-v1.png` | 1214×1295 | 是 |

## 场景定位

### 菌灯洞窟

- 视觉：灰褐岩壁、潮湿泥地、青绿色菌灯、火盆、木栈道、生活营地和少量废弃科技结构。
- 布局：南侧入口、中央营地、西侧采集区、东侧浅水绕行路、北侧封闭石门。
- 玩法方向：主路加两条回环支路；后续可加入暖芯菌、锅炉、牢笼、补给箱和绞盘。

### 赤晶祭坛

- 视觉：黑色玄武岩、深紫阴影、赤红晶体、冷白遗迹符文、深渊环道和悬浮核心。
- 布局：南侧入口、中央环道、左右两条接近路线、北侧祭坛、东侧宝物平台。
- 玩法方向：后续可加入三晶共鸣、断桥控制、冰刀宝箱、长剑密室和限时撤离。

两张地图保留《零域协议》的世界观解释：哥布林是受零域孢子与遗迹辐射影响的穴居类人种；洞穴越深，遗迹科技与异常能量越明显。

## 怪物定位与首测数值

### 巨型哥布林「岩背」

- 定位：高生命、高防御、蓄力重击的精英近战怪。
- 首测：HP 560、攻击倍率 1.15、防御倍率 1.25、经验 150、信用点 70（均为占位值）。
- 招式：岩锤横扫；蓄力砸地（提前一回合预警）；50% HP 时一次性岩甲护体。
- 设计目的：教玩家识别预警并使用防御。

### 哥布林祭祀「幽孢祷者」

- 定位：中等生命、削减 MP、吟唱与异常状态型法师。
- 首测：HP 340、普通攻击倍率 0.80、法术倍率 1.25、防御倍率 0.85、经验 175、信用点 55（均为占位值）。
- 招式：孢子弹；枯竭咒（削减 15 MP）；深穴仪式（可被高伤技能打断）；35% HP 时一次性菌幕。
- 设计目的：让玩家管理 MP，并学习在吟唱窗口进行爆发。

首版建议继续使用单敌回合制，不让两种精英同时出场，避免在本阶段扩建多目标战斗系统。

## 本轮生成提示词

### 菌灯洞窟

```text
Create a finished 2D hand-painted RPG exploration map background for the game "Zero Domain Protocol". Landscape 3:2 composition, semi-top-down orthographic view, designed as a navigable playable map rather than a cinematic illustration. Location: the ordinary goblin cave called "Fungus-Lamp Cavern". Gray-brown rock walls, damp earth, shallow water, moss, teal bioluminescent mushrooms, warm crude braziers, wooden plank walkways, rough goblin huts and supply cages, with a few exposed old cables and damaged sci-fi light strips subtly implying buried technological ruins. Clear southern entrance camp, western gathering pit, broad central camp arena, eastern shallow-water bypass, and a large sealed stone gate on the north edge leading deeper underground. Use one obvious main route plus two readable looping side paths, broad walkable corridors, clear collision-friendly rock boundaries, and empty encounter spaces suitable for placing player and enemies later. No characters, no creatures, no UI, no labels, no arrows, no text, no watermark. Distinctly brighter, wider, and more inhabited than the deep cave. Avoid side view, horizon line, extreme isometric tilt, cluttered impassable maze, photorealism, embedded treasure UI.
```

### 赤晶祭坛

```text
Create a finished 2D hand-painted RPG exploration map background for the game "Zero Domain Protocol". Landscape 3:2 composition, semi-top-down orthographic view, designed as a navigable playable map. Location: the cave depths called "Crimson Crystal Altar". Visually and immediately distinct from an ordinary brown cave: black basalt, deep violet shadows, vivid crimson crystal pillars, cold white ancient technological runes, a circular ritual platform above a dark underground abyss, broken stone bridges and fragments of buried metallic ruins. Clear southern fault entrance, western ritual corridor with rune pillars, eastern crystal-vein side chamber with an empty raised treasure pedestal, central ring walkway around the abyss with three reconnectable bridge segments, large northern boss altar, and a sealed chamber behind it. Red dust motes drift toward a suspended anomalous core, but effects must not hide paths. Two readable approaches to the altar, broad walkable paths and clear collision-friendly boundaries. Ominous, geometric, compressed and ceremonial, unlike the brighter lived-in upper cave. No characters, no creatures, no UI, no labels, no arrows, no text, no watermark. Avoid side view, horizon line, extreme isometric tilt, cluttered impassable maze, photorealism.
```

### 巨型哥布林「岩背」

```text
Create a production-quality full-body 2D enemy character asset for a dark hand-painted anime RPG, "Zero Domain Protocol". Character: an adult non-human giant goblin elite named Rockback, approximately twice the height of a normal goblin. Massive inverted-triangle silhouette, extremely broad shoulders, long powerful arms, hunched posture, rough gray-green skin, cave rock plates and small glowing fungi fused across its back. Wears crude salvaged metal shoulder armor and a miner belt, carries a huge two-handed impact hammer built from broken starship machinery and stone. Rust red and muted ochre accents, intimidating and heavy, readable at game scale. Three-quarter view facing right toward the player, aggressive ready stance, entire weapon, hands, feet and silhouette visible, clean separation between limbs. Transparent background with genuine alpha, no ground plane, no cast shadow, no scenery, no border, no UI, no text, no logo, no watermark. Do not make it cute, childlike, human, gory, or photorealistic. Avoid cropped feet, extra limbs, malformed hands, checkerboard background, flat colored background.
```

### 哥布林祭祀「幽孢祷者」

```text
Create a production-quality full-body 2D enemy character asset for a dark hand-painted anime RPG, "Zero Domain Protocol". Character: an adult non-human goblin shaman called Spore Prayer. Lean, tall, hunched narrow-triangle silhouette, deep teal-green skin, high bone ritual mask and filament-fungus crown. Patched robe sewn from damaged thermal cloth, bone plates and old data cables. Holds a twisted fungus-wood staff with a levitating violet-blue crystal at the top; a restrained halo of sparse glowing spores surrounds the staff without obscuring the body. Visually distinct from a giant warrior: fragile, occult, intelligent and dangerous. Three-quarter view facing right toward the player, spellcasting-ready pose, entire staff, hands, feet and silhouette visible, readable at game scale. Transparent background with genuine alpha, no ground plane, no cast shadow, no scenery, no border, no UI, no text, no logo, no watermark. Adult non-human monster, not cute or childlike, no gore, no photorealism. Avoid cropped feet, extra limbs, malformed hands, checkerboard background, flat colored background.
```
