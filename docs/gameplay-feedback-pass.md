# RPG 可玩性反馈改进 v0.1

日期：2026-09-05。

本轮不进行 ACT 类型重构，先修复 RPG 原型最影响可玩性的三个问题：不知道去哪里、任务入口不可见、战斗缺少状态与结算反馈。

## 当前路线

余烬村回收归潮协议后，HUD 会持续指向“游隼·返航”并显示距离，目标点上方显示黄色感叹号。返回 H1 后指向基地电梯；向沈砚汇报后，他头顶出现感叹号，对话直接开放《红钻清算》。任务也保留在 `C → 任务与支线` 中，作为第二入口。

## 战斗反馈

- 胜利时显示战斗回合、总伤害、剩余 HP/MP 和奖励结算方式，再自动返回探索。
- 角色立绘在敌方伤害结算后立即按当前血量重新取图。
- 重甲低于 50% 使用 `lyra-heavy-stage-1-v1.png`。
- 低于 25% 的重度重甲差分、赤线两档差分尚无合格透明素材；当前回退逻辑会明确说明，不再假装素材已经完成。

## 类型建议

短期保持 RPG。现有价值集中在任务状态、路线选择、装备风险、线索解谜和角色支线；转 ACT 会要求重写碰撞盒、攻击帧、敌人 AI、硬直、闪避、镜头与关卡空间，但不会自动修复目标不清和反馈不足。后续若想增强动作性，建议先采用“回合制 RPG + QTE 防御/破招/状态挣脱”的混合方案，再以一场首领战验证是否值得全面转型。

## 本轮采用的图像编辑提示词

内置 imagegen，编辑目标为 `lyra-heavy-injury-stage1-concept-v1.png`：

```text
Use case: background-extraction
Asset type: production-ready transparent full-body RPG battle portrait, heavy armor damage stage 1
Input image: the supplied local image is the exact edit target
Primary request: preserve the adult heroine, face, hairstyle, pose, weapon, white-and-black heavy armor, moderate scratches and all body proportions exactly; remove the baked gray-and-white checkerboard background completely and replace it with genuine transparent alpha
Composition: preserve the complete head, ponytail, weapon, boots and silhouette without cropping
Constraints: change only the background; clean antialiased transparent edges; one adult character; fully clothed; no new damage, no blood, no text, no watermark
```

该输出已经验证含真实 Alpha 并接入项目。对重甲二阶段和赤线两阶段的另外三次编辑输出未通过 Alpha 验证，均未复制进项目或接入代码。
