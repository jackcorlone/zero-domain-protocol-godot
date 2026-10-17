# 裂隙下的微光：洞穴静态漫画方案

2026-09-04。Game Designer 与 Godot Gameplay Scripter 协作设计。本轮只有三张插图和设计文档，没有修改游戏脚本、没有实现新地图或播放动画，未运行测试或启动 Godot。

## 进入方式

推荐主动探索，战后发现作为可选提示。位置为已存在的 ECHO-9 裂隙栈道（ravine）。
清理附近敌人后，碎石滑落露出裂口，扫描器捕捉到旧装备箱信号；玩家也可以在绕行探索时发现它。检查后选择“进入调查／暂时离开”，不强制胜利后失足跌落。
若以后需要坠落，可留给必须推进的主线事故，不作为普通宝箱奖励前的强制惩罚。

## 三张分镜

1. assets/story/cave-entry-v1.png：探入。入口冷光与低岩顶形成明确边界，凌霁双臂和上身进入岩道，腿部仍在外侧。旁白：“信号就在后面。先看看通道。”
2. assets/story/cave-crawl-v1.png：穿行。侧面展示低矮空间，肘部支撑、膝盖推进，前方微光指引出口。旁白：“沿着管线……前面有光。”
3. assets/story/cave-exit-v1.png：脱困。暗室视角看她上半身探出洞口，双手撑住岩沿，远处是仍关闭的旧装备箱。旁白：“终于……找到你了。”

三图均为 16:9 横幅静态插图，使用现有凌霁黑白装甲、高马尾和青色照明。衣物完整，危险由岩层、空间和动作表现。不要将画面视为精确碰撞图或逐帧动画。

## 漫画演出建议（未实现）

淡入约 0.35 秒，每格轻微推近或横移 2%–4%，玩家点击继续；可减少动态效果。配合摩擦、落砂、呼吸与箱体提示音，声音尚未制作。字幕由 UI 叠加，不烘焙到图片。
跳过只跳到抵达暗室，不自动发奖；重播不改状态。恢复控制后亲手开箱，之后开启检修门返回裂隙栈道安全点，无需再次爬行。第一版可只采用模态场景与返回，不必同时开发可行走洞穴。
宝箱内容尚待技能系统确定；可先定位为旧设备模块与探索记录，不绑定未实现技能、不锁主线。

## 后续最小技术接点（未实施）

现有 scripts/expedition.gd 的 ravine 交互点可增加入口；scripts/expedition_maps.gd 当前没有洞穴地图。
现有 scripts/luo_story_scene.gd 提供静态图加 Tween 的参考，但其参数绑定罗茂剧情，不直接复用。
如获准实现，可新增独立漫画 Control，以 finished/cancelled 信号通知地图恢复控制；独立存档字段 discovered、traversed、chest_claimed，旧档均默认 false，不复用现有测绘箱字段。
奖励先检查 chest_claimed，再按现有存档流程结算一次；退出、跳过和重播均不能重复领取。若做可走地图，需另补出生点、出口、碰撞和合法地点校验。

## 生成记录

使用内置 imagegen 技能与工具，未使用 CLI。参考：assets/characters/lyra-portrait-2d-v1.png（角色与服装）；首张初稿也用于统一后两张风格。生成原稿均保留。第一张初稿半身内外界限不明确，进行了单次洞口构图修订，采用修订图。

### entry 完整提示词

```text
Use case: illustration-story. Create one landscape 16:9 static comic cutscene illustration for a sci-fi exploration RPG, detailed 2D anime ink and cel shading. Reference image is character identity and costume reference only: adult heroine Ling Ji, black high ponytail, amber brown eyes, fully covered practical black and ivory segmented armor with small cyan lights, gloves and boots. Preserve this outfit throughout, no drawn sword in the confined passage. Rocky natural cave intersecting buried old sci-fi infrastructure, blue-grey stone, faint cyan conduit, sparse dust. Serious resourceful adventure tone, no sexual framing, no torn clothes, no body-part emphasis, no text, captions, watermarks or panel borders. Scene 1: entering a low natural rock crawlspace. Side-on medium-wide view along the passage, a small portion of near rock shown in cutaway so the action is clear. Her head, shoulders, arms and upper torso are already inside the narrow passage; hips and booted legs still on the entrance ledge. She advances head-first from left to right, supporting herself on both gloved forearms, carefully inspecting stable footholds, alert face visible in profile. Back level, realistic low crawling posture. Passage has enough clearance for armored shoulders but is too low to stand, not a body-tight circular hole. Strong visible rock thickness, entrance ambient light behind her, cyan wrist lamp illuminating rock ahead. Emphasize face, hands and spatial storytelling, not rear view.
```

### crawl 完整提示词

```text
Use case: illustration-story. Create one landscape 16:9 static comic cutscene illustration for a sci-fi exploration RPG, detailed 2D anime ink and cel shading. Reference image is character identity and costume reference only: adult heroine Ling Ji, black high ponytail, amber brown eyes, fully covered practical black and ivory segmented armor with small cyan lights, gloves and boots. Preserve this outfit throughout, no drawn sword in the confined passage. Rocky natural cave intersecting buried old sci-fi infrastructure, blue-grey stone, faint cyan conduit, sparse dust. Serious resourceful adventure tone, no sexual framing, no torn clothes, no body-part emphasis, no text, captions, watermarks or panel borders. Scene 2: the same heroine is entirely INSIDE the low horizontal rock passage, crawling from left to right. Side-on sectional cinematic view, near wall omitted to show her full figure and continuous rock ceiling and floor. She pulls forward using forearms while one knee braces against the ground, back kept low and level, ponytail trailing naturally. Focus on determined face, gloved hand testing a rock, careful boot placement, small falling grit conveying effort. Practical physically credible crawling, no exaggerated arched back. Dim cyan wrist lamp and a distant warm slit of light ahead. Environment occupies half of frame to communicate confined geography. No other characters.
```

### exit 完整提示词

```text
Use case: illustration-story. Create one landscape 16:9 static comic cutscene illustration for a sci-fi exploration RPG, detailed 2D anime ink and cel shading. Reference image is character identity and costume reference only: adult heroine Ling Ji, black high ponytail, amber brown eyes, fully covered practical black and ivory segmented armor with small cyan lights, gloves and boots. Preserve this outfit throughout, no drawn sword in the confined passage. Rocky natural cave intersecting buried old sci-fi infrastructure, blue-grey stone, faint cyan conduit, sparse dust. Serious resourceful adventure tone, no sexual framing, no torn clothes, no body-part emphasis, no text, captions, watermarks or panel borders. Scene 3: from INSIDE the destination chamber looking obliquely toward the rock crawlspace exit, heroine has finally pulled her head, shoulders, arms and upper torso out of the low opening; waist and legs remain naturally concealed within the tunnel. Both gloved hands and forearms brace on a wide stable stone ledge as she exhales with relief and determination, slightly dusty intact armor. Compose medium-wide three-quarter front view, face and hands focal, no chest closeup. Across the chamber clearly show the reward: a closed rugged old sci-fi salvage chest with amber status lamp atop a low plinth, linked to a worn cable on the cave wall. Dark blue cave lit by warm amber chest light and faint cyan wrist light; sense of discovery after effort. Maintain enough space around shoulders, no rock passing through anatomy.
```

### entry 构图修订

```text
Use case: precise-object-edit. Edit this cave entry comic illustration. Preserve the adult heroine Ling Ji identity, intact black and ivory armor, cyan wrist light, ponytail, side-on crawling action facing right and anime cel-shaded style. Change ONLY staging of the entrance: make this clearly HALF ENTERED into the passage, not already fully inside. Wide side cutaway composition: LEFT HALF of image is a spacious cave vestibule with a tall ceiling and cool daylight, her hips, knees and both boots on its flat ledge; RIGHT HALF is the LOW rock passage with a thick rock ceiling descending at the center exactly over her mid torso. Head, shoulders, both gloved forearms are under that low ceiling. Anatomically continuous whole body, shoulder clearance, back level, supported knees and elbows. Near wall omitted for readable comic sectional view. Clear vertical lip of rock overhead dividing spacious entrance and low tunnel, no rock intersecting her body. Face and hands still visible in profile, no rear viewpoint, no body-part closeup, no text. Landscape 16:9.
```

- cave-entry-v1.png ← /Users/xuzhe/.codex/generated_images/01a0502b-6c32-7050-b773-7a2d7f69aa69/exec-9ab8747c-8cd8-4f2d-8071-0f3f22aab3e4.png
- cave-crawl-v1.png ← /Users/xuzhe/.codex/generated_images/01a0502b-6c32-7050-b773-7a2d7f69aa69/exec-ebe395d3-c4d3-424a-af9b-9178ca4a2720.png
- cave-exit-v1.png ← /Users/xuzhe/.codex/generated_images/01a0502b-6c32-7050-b773-7a2d7f69aa69/exec-f12c6364-142e-41f6-aeb1-875e9ba4a743.png

