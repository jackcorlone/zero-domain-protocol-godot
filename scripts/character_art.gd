extends RefCounted

const HEAVY := preload("res://assets/characters/lyra-portrait-2d-v1.png")
const REDLINE := preload("res://assets/characters/lyra-redline-intact-v1.png")


static func portrait(state: ZeroDomainGameState) -> Texture2D:
	var path := damage_path(state)
	if state.armor_stage() > 0 and ResourceLoader.exists(path):
		return load(path) as Texture2D
	if state.armor_stage() == 2:
		var stage_one := damage_path_for(state, 1)
		if ResourceLoader.exists(stage_one):
			return load(stage_one) as Texture2D
	return REDLINE if state.equipped_armor == "redline" else HEAVY


static func art_note(state: ZeroDomainGameState) -> String:
	if state.armor_stage() == 2 and not ResourceLoader.exists(damage_path(state)) and ResourceLoader.exists(damage_path_for(state, 1)):
		return "重度战损差分待补 · 使用一阶段"
	return "战损立绘待补 · 当前显示完整造型" if state.armor_stage() > 0 and not ResourceLoader.exists(damage_path(state)) else ""


static func damage_path(state: ZeroDomainGameState) -> String:
	return damage_path_for(state, state.armor_stage())


static func damage_path_for(state: ZeroDomainGameState, stage: int) -> String:
	var outfit := "redline" if state.equipped_armor == "redline" else "heavy"
	return "res://assets/characters/lyra-%s-stage-%d-v1.png" % [outfit, stage]
