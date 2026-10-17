class_name VoyageEncounters
extends RefCounted

const ENEMIES := {
	"voyage_tide_root": {"name": "潮须潜根", "map": "tentacle_field", "hp": 160, "damage": Vector2i(36, 44), "exp": 120, "credits": 28, "skill": "缠根：每3回合束缚，下一次攻击伤害降低25%", "drop": "潮须纤维", "sheet": "voyage-tentacle-roster-v1.png", "region": Rect2(0, 170, 520, 800)},
	"voyage_spore_drifter": {"name": "孢囊漂体", "map": "tentacle_field", "hp": 125, "damage": Vector2i(28, 36), "exp": 135, "credits": 32, "skill": "再生孢雾：每3回合回复45 HP，最多2次", "drop": "净化孢囊", "sheet": "voyage-tentacle-roster-v1.png", "region": Rect2(430, 100, 620, 820)},
	"voyage_root_matriarch": {"name": "根冠母体 · 精英", "map": "tentacle_field", "hp": 430, "damage": Vector2i(48, 64), "exp": 390, "credits": 135, "skill": "根冠屏障：每3回合使下一次所受伤害降低40%", "drop": "根冠核心", "sheet": "voyage-tentacle-roster-v1.png", "region": Rect2(850, 0, 686, 1024)},
	"voyage_tide_acolyte": {"name": "潮印侍从", "map": "eldritch_ruins", "hp": 180, "damage": Vector2i(38, 46), "exp": 155, "credits": 35, "skill": "复诵惩戒：连续使用同一指令时伤害提高40%", "drop": "潮印碎片", "sheet": "voyage-ruins-roster-v1.png", "region": Rect2(0, 120, 520, 850)},
	"voyage_faceless_observer": {"name": "无面观测体", "map": "eldritch_ruins", "hp": 145, "damage": Vector2i(32, 42), "exp": 170, "credits": 38, "skill": "观测反射：每3回合抽取18 MP", "drop": "观测透镜", "sheet": "voyage-ruins-roster-v1.png", "region": Rect2(400, 80, 620, 880)},
	"voyage_mnemonic_choir": {"name": "逆谱合唱体 · 精英", "map": "eldritch_ruins", "hp": 400, "damage": Vector2i(44, 60), "exp": 420, "credits": 150, "skill": "认知失真：第3回合发动1.6倍精神冲击", "drop": "逆谱声核", "sheet": "voyage-ruins-roster-v1.png", "region": Rect2(850, 0, 686, 1024)},
	"voyage_rift_fin": {"name": "裂鳍猎兽", "map": "storm_sea", "hp": 170, "damage": Vector2i(40, 48), "exp": 150, "credits": 34, "skill": "跃浪扑杀：每3回合发动1.75倍伤害", "drop": "裂鳍", "sheet": "voyage-sea-roster-v1.png", "region": Rect2(0, 170, 570, 800)},
	"voyage_storm_medusa": {"name": "引雷水母", "map": "storm_sea", "hp": 135, "damage": Vector2i(30, 40), "exp": 165, "credits": 36, "skill": "导电印记：每3回合抽取20 MP并提高本次伤害", "drop": "蓄雷胶质", "sheet": "voyage-sea-roster-v1.png", "region": Rect2(430, 80, 620, 870)},
	"voyage_ridgebeast": {"name": "深潮脊兽 · 精英", "map": "storm_sea", "hp": 460, "damage": Vector2i(52, 72), "exp": 450, "credits": 165, "skill": "深潮狂怒：HP低于40%后每2回合重击", "drop": "深潮脊骨", "sheet": "voyage-sea-roster-v1.png", "region": Rect2(850, 0, 686, 1024)},
}

const MAP_ENEMIES := {
	"tentacle_field": ["voyage_tide_root", "voyage_spore_drifter", "voyage_root_matriarch"],
	"eldritch_ruins": ["voyage_tide_acolyte", "voyage_faceless_observer", "voyage_mnemonic_choir"],
	"storm_sea": ["voyage_rift_fin", "voyage_storm_medusa", "voyage_ridgebeast"],
}


static func has(encounter_id: String) -> bool:
	return ENEMIES.has(encounter_id)


static func config(encounter_id: String) -> Dictionary:
	return ENEMIES.get(encounter_id, {})


static func texture(encounter_id: String) -> AtlasTexture:
	var data: Dictionary = config(encounter_id)
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://assets/enemies/" + str(data.sheet))
	atlas.region = data.region
	return atlas


static func npc_texture(region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://assets/npcs/voyage-starport-npc-sheet-v1.png")
	atlas.region = region
	return atlas
