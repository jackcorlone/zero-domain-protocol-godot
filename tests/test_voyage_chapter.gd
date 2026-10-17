extends SceneTree

var failed := false


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: ZeroDomainGameState = root.get_node("GameState")
	state.reset()
	state.quest_state = state.QuestState.COMPLETE
	state.echo.accepted = true
	state.echo.reward_claimed = true
	_check(state.accept_voyage(), "完成回声外勤后可接潮汐盲区")
	_check(state.choose_voyage_module("insulation"), "贺岑模块只能从有效选项领取")
	_check(not state.choose_voyage_module("battery"), "航务模块不可重复领取")
	_check(state.claim_anti_adhesion_spray() and state.voyage.sprays == 1, "祁雾应发放一份抗黏附喷剂")
	var rules := preload("res://scripts/voyage_encounters.gd")
	_check(rules.ENEMIES.size() == 9, "三张地图必须各有三种敌人")
	for map_id: String in rules.MAP_ENEMIES:
		_check(rules.MAP_ENEMIES[map_id].size() == 3, map_id + " 必须包含两只普通怪和一只精英怪")
		for enemy_id: String in rules.MAP_ENEMIES[map_id]:
			var data: Dictionary = rules.config(enemy_id)
			_check(data.hp > 0 and data.damage.x > 0 and data.exp > 0 and not str(data.skill).is_empty(), enemy_id + " 数值和技能必须完整")
			_check(rules.texture(enemy_id).atlas != null, enemy_id + " 必须能显示已批准的设定表素材")
	state.saved_location = "starport"
	var scene: Node = load("res://scenes/expedition.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	_check(scene.location_id == "starport" and scene.points.has("he_cen") and scene.points.has("qi_wu"), "星港应包含两名可交互 NPC")
	for map_id: String in rules.MAP_ENEMIES:
		scene._set_location(map_id)
		for enemy_id: String in rules.MAP_ENEMIES[map_id]:
			_check(scene.points.has(enemy_id), map_id + " 缺少敌人交互点 " + enemy_id)
	var sample_id := "voyage_tide_root"
	scene._set_location("tentacle_field")
	scene._start_voyage_battle(sample_id)
	_check(scene.battle_screen.enemy_max_health == rules.config(sample_id).hp, "战斗 HP 必须来自敌人配置")
	scene.battle_screen._perform_action("retreat")
	var before_exp: int = state.experience
	var sample: Dictionary = rules.config(sample_id)
	_check(state.record_voyage_victory(sample_id, sample.credits, sample.exp, sample.drop), "战斗胜利应记录击败、奖励和材料")
	_check(state.experience == before_exp + sample.exp and state.voyage.materials[sample.drop] == 1, "EXP 与掉落应按配置结算")
	_check(not state.record_voyage_victory(sample_id, sample.credits, sample.exp, sample.drop), "同一固定敌人不能重复刷一次性奖励")
	state.save_path = "/private/tmp/zero-domain-voyage-%d.cfg" % OS.get_process_id()
	state.persistence_enabled = true
	_check(state.save_progress() == OK, "潮汐盲区进度应可保存")
	state.reset()
	_check(state.load_progress() and state.saved_location == "tentacle_field" and sample_id in state.voyage.defeated, "地点、击败记录和材料应能读档恢复")
	if not failed:
		print("VOYAGE_CHAPTER_OK")
	quit(1 if failed else 0)
