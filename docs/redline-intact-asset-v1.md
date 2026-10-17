# 赤线完整立绘 · 透明游戏素材

输入：`assets/characters/lyra-redline-concept-v2.png`。

输出：`assets/characters/lyra-redline-intact-v1.png`，1024×1536；使用内置 imagegen 对参考图编辑，`sips -g hasAlpha` 确认 alpha 通道。旧概念图保留。此图是完整服装，不是破甲图。

提示词：

> Extract this entire adult heroine in her black Redline tactical suit as a transparent PNG game sprite cutout. Remove grey background and floor shadow only, preserve face hair body pose costume red seams cyan sword and full-body placement, same1024x1536canvas. Actual alpha transparency, no checkerboard or solid background. Clothes remain opaque, no new elements.

后续重甲透明版与罗老板立绘请求遇到图片服务 `usage_limit_reached`。没有擅自切换 API 或把未返回的图标记为已完成；阶段 1、2 图仍缺失。接入规则见 `scripts/character_art.gd`。
