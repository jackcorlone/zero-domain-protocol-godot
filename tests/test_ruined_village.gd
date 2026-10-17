extends SceneTree

var failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _settle() -> void:
	for frame: int in range(4):
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)


func _write_legacy_v2_save(state: ZeroDomainGameState, path: String) -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "version", 2)
	config.set_value("expedition", "echo", state.ECHO_DEFAULTS.duplicate(true))
	config.set_value("luo_story", "progress", state.LUO_STORY_DEFAULTS.duplicate(true))
	for field: String in state.SAVE_FIELDS:
		config.set_value("progress", field, state.get(field))
	_check(config.save(path) == OK, "旧版 v2 测试存档应可写入")


func _run() -> void:
	var state: ZeroDomainGameState = root.get_node("GameState")
	var save_path := "/private/tmp/zero-domain-ruined-village-%d.cfg" % OS.get_process_id()
	state.reset()
	_write_legacy_v2_save(state, save_path)
	state.save_path = save_path
	_check(state.load_progress(), "缺少 ruined_world 分区的旧 v2 存档应使用默认值加载")
	_check(not state.ruins.accepted and state.ruins.clues.is_empty() and not state.ruins.secret_recovered, "旧存档的灰烬遗言进度应为未开启")

	state.reset()
	state.save_path = save_path
	state.persistence_enabled = true
	state.quest_state = state.QuestState.COMPLETE
	state.echo.accepted = true
	state.echo.outcome = "keep"
	state.echo.reward_claimed = true
	_check(state.accept_ruins_mission(), "回声之外汇报后应可接取灰烬遗言")
	_check(state.secure_ruins_shelter(), "必须先稳定幸存者避难所")
	_check(state.collect_ruins_clue("crater") and not state.recover_phase_secret(), "一份记录不足以回收归潮协议")
	_check(state.collect_ruins_clue("observatory") and state.ruins.clues.size() == 2, "三处调查中任取两处应满足门槛")

	state.saved_location = "ruin_vault"
	change_scene_to_file("res://scenes/expedition.tscn")
	await _settle()
	current_scene._start_puzzle("phase_lock")
	current_scene._puzzle_choose("锁频")
	_check(current_scene.puzzle_progress == 0 and not state.ruins.secret_recovered, "归潮协议顺序错误应安全重置")
	for action: String in ["反相", "延迟两拍", "锁频"]:
		current_scene._puzzle_choose(action)
	_check(state.ruins.secret_recovered, "正确序列应回收归潮协议")

	current_scene._set_location("ruined_village")
	_check(current_scene.background.texture.resource_path.ends_with("aspera-ember-village-map-v1.png"), "余烬村应使用独立俯视RPG地图，不再复用航母CG")
	current_scene._process(0.0)
	_check(current_scene._objective_point_id() == "boarding", "回收归潮协议后任务指引应指向游隼")
	_check(current_scene.objective_guide.text.contains("游隼") and current_scene.points.boarding.node.get_node("QuestBadge").visible, "HUD方向提示与目标感叹号应同时指向返航点")
	current_scene._fly("hangar")
	current_scene._finish_flight()
	current_scene._fly("ruined_village")
	current_scene._finish_flight()
	_check(current_scene.mode == current_scene.Mode.MODAL and current_scene.dialogue_name.text.contains("遮天"), "抵达余烬村时应播放航母过场")
	_check(current_scene.luo_story_picture != null and current_scene.luo_story_picture.texture.resource_path.ends_with("eclipse-carrier-ruins-v1.png"), "原航母图应作为CG而不是可走地图")
	current_scene._close_modals()
	current_scene._fly("hangar")
	current_scene._finish_flight()
	current_scene._return_base()
	await _settle()
	_check(current_scene.scene_file_path == "res://scenes/exploration.tscn" and state.saved_location == "command", "废弃村庄任务应可返回指挥中心汇报")
	var credits_before: int = state.credits
	current_scene._report_ruins_mission()
	current_scene._report_ruins_mission()
	_check(state.ruins.reported and state.credits == credits_before + 450, "灰烬遗言奖励只能结算一次")
	_check(state.load_progress() and state.ruins.reported and state.ruins.secret_recovered, "归潮协议与汇报状态应可从存档恢复")
	if not failed:
		print("RUINED_VILLAGE_OK")
	quit(1 if failed else 0)
