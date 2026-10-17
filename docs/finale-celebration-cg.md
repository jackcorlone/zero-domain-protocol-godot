# 终章 CG：英雄归航与白色星夜

生成日期：2026-09-09。使用 imagegen 技能和内置图像生成工具（非 CLI）。两张图均已复制到工程；原图保留在 Codex 生成目录。

## 剧情定位

Game Designer 将两张 CG 设计成连续段落：

1. 「英雄归航」：凌霁结束危险任务，穿黑白重甲从游隼返回 H1 机库，沈砚、岑遥与基地成员迎接。
2. 「白色星夜」：庆功后，基地观景环举行舞会。成年凌霁换上华丽白色蕾丝抹胸长裙，与成年沈砚慢舞、拥抱并亲吻。

男方暂按沈砚表现，因为他是现有主线中与凌霁建立信任的成年男性角色；不是罗老板。舞会亲吻只适合在玩家明确确认恋爱路线后出现，不应由普通任务完成自动替玩家选择。

Godot Gameplay Scripter 的只读检查认为，这组“全基地庆功＋恋爱确认”最适合接在终章岳沉戈战败后的真结局，而不是早期「回声之外」汇报。推荐触发点是 `scripts/finale.gd` 的真结局流程；本轮只生成并保存 CG，没有改剧情触发代码或存档结构。

## 文件

- [英雄归航](../assets/story/lyra-base-celebration-v1.png)：1672×940 RGB PNG。
- [白色星夜](../assets/story/lyra-shen-dance-kiss-v1.png)：1672×941 RGB PNG。

两张都是完整横版剧情画面，不需要透明背景。

## 最终提示词

### 英雄归航

```text
Use case: illustration-story.
Asset type: finished 16:9 story CG for the 2D sci-fi RPG “Zero Domain Protocol”.
Input images: Image 1 is the adult heroine Ling Ji / LYRA-7 identity and black-and-ivory heavy armor reference; preserve her face, amber-brown eyes, long black high ponytail, adult proportions, ivory-and-black armor and cyan details. Image 2 is Commander Shen Yan’s identity cue. Image 3 is the established cinematic painted rendering, world design, and relationship continuity reference.
Primary request: after completing the dangerous unknown-region mission, Ling Ji returns safely to SITE OMEGA and the base celebrates her homecoming.
Scene/backdrop: the warm-lit H1 shuttle hangar inside the arctic sci-fi base, the compact shuttle “Peregrine” parked behind with its boarding ramp lowered, cyan control consoles and metal architecture.
Subject/action: Ling Ji has just stepped off the ramp in intact black-and-ivory heavy armor with only light frost and travel dust, standing proudly but emotionally relieved. Adult Commander Shen Yan welcomes her at the foot of the ramp with a sincere smile. The adult female engineer in an orange insulated jumpsuit and base crew form a semicircle applauding; a few restrained gold-and-white paper streamers in the air.
Style/medium: polished hand-painted anime RPG story CG, detailed cinematic sci-fi illustration, visually consistent with Image 3, not chibi, not photorealistic.
Composition/framing: 16:9 landscape, low wide camera, Ling Ji as central hero, shuttle ramp creates leading lines, Shen Yan close enough to show their mutual warmth, supporting crew readable but secondary.
Lighting/mood: cold cyan hangar rim lights transitioning into warm gold celebration light; relief, earned honor, belonging, restrained joy.
Constraints: all characters visibly adult; preserve Ling Ji identity and armor; no kiss yet; no text, lettering, logos, watermarks, UI, medals ceremony, outdoor city, extra weapons, blood, torn clothing, sexualized pose, or cropped main figures.
```

### 白色星夜

```text
Use case: illustration-story.
Asset type: finished 16:9 romance-route story CG for the 2D sci-fi RPG “Zero Domain Protocol”.
Input images: Image 1 is the adult heroine Ling Ji identity reference; preserve her face, amber-brown eyes and long black high ponytail but change her clothing as requested. Image 2 is adult Commander Shen Yan’s identity cue. Image 3 is the established cinematic painted rendering and their relationship continuity reference.
Primary request: after the base victory celebration and after both adults have voluntarily confirmed their romance, Ling Ji and the handsome adult Commander Shen Yan slow-dance, embrace, and share a tender kiss; they feel like a perfectly matched heroic couple.
Scene/backdrop: SITE OMEGA observation ring temporarily transformed into an elegant evening ballroom, panoramic window showing stars, the returning Peregrine shuttle, subtle moving base lights, a few adult guests only as soft-focus silhouettes.
Subject/action: Ling Ji wears a lavish floor-length white lace strapless ball gown with an opaque lined fitted bodice, sculpted floral lace, narrow waist, layered luminous skirt and long sweeping hem. No armor. Shen Yan wears a handsome tailored black formal commander uniform with restrained gold trim. Their bodies are in a graceful slow-dance turn; his arm securely around her waist and upper back, her arm around his shoulder, their other hands gently linked, eyes closed as they kiss. The embrace and kiss are mutual, tender and romantic.
Style/medium: polished hand-painted anime RPG romance CG, elegant cinematic illustration, visually consistent with Image 3, not chibi, not photorealistic.
Composition/framing: 16:9 landscape medium-full shot, both adult figures visible from head through flowing lower gown, white dress luminous against his dark uniform, skirt retains a graceful turning arc.
Lighting/mood: blue starlight and soft warm champagne rim light, intimate, serene, joyful, emotionally certain, “made for each other.”
Constraints: all characters adults; consensual tenderness; preserve Ling Ji and Shen Yan identities; the strapless gown must remain fully opaque and securely fitted; tasteful formal romance, no nudity, no lingerie, no transparent bodice, no bedroom, no sexual activity, no text, lettering, logos, watermark, UI, extra foreground couple, or cropped faces.
```

## 建议接入条件

- 庆功 CG：终章胜利且真结局确认后播放。
- 舞会 CG：庆功后提供明确选项，如「接受沈砚的邀请」；拒绝时不播放亲吻画面。
- 存档建议增加 `celebration_seen` 与 `dance_seen`，防止重复强制播放，并兼容旧存档。
- 如果玩家尚未确认沈砚恋爱路线，可改为并肩看星空，不触发亲吻。

