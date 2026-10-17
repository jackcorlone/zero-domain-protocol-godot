extends SceneTree

const SETTINGS := preload("res://scripts/game_settings.gd")
var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)


func _capture(name_value: String) -> void:
	for frame: int in range(6):
		await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/private/tmp/zero-domain-hub-%s.png" % name_value)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state: ZeroDomainGameState = root.get_node("GameState")
	state.reset()
	state.save_path = "/private/tmp/zero-domain-hub-%d.cfg" % OS.get_process_id()
	SETTINGS.settings_path = "/private/tmp/zero-domain-settings-%d.cfg" % OS.get_process_id()
	var scene: Node = load("res://scenes/exploration.tscn").instantiate()
	root.add_child(scene)
	_check(scene.commander_quest_badge.visible, "可接主线时沈砚头顶应显示感叹号")
	scene._open_character()
	_check(scene.character_stats.text.contains("HP <50% 一阶段破损；HP <25% 二阶段破损"), "角色状态应正确显示新阈值")
	_check(scene.character_tabs.get_tab_count() == 3, "角色、任务、系统三页")
	_check(not scene.player.controls_enabled, "菜单打开时冻结移动")
	await _capture("character")
	_check(scene.character_panel.get_global_rect().end.x <= 1280 and scene.character_panel.get_global_rect().end.y <= 720, "人物面板不得越界")
	scene.character_tabs.current_tab = 1
	await _capture("tasks")
	_check(scene.task_summary.text.contains("罗老板") and scene.task_summary.text.contains("维护支路"), "任务面板包含支线目标")
	scene.character_tabs.current_tab = 2
	_check(scene._manual_save() and FileAccess.file_exists(state.save_path), "手动保存应写入磁盘")
	_check(state.load_progress(), "手动保存可读取")
	await _capture("system")
	state.battle_active = true
	_check(not scene._manual_save(), "战斗中拒绝保存")
	state.battle_active = false
	var valid_path: String = state.save_path
	state.save_path = "/private/tmp/zero-domain-nonexistent-%d/progress.cfg" % OS.get_process_id()
	_check(not scene._manual_save() and scene.system_feedback.text.contains("失败"), "写入失败不得谎报成功")
	state.save_path = valid_path
	scene._close_modals()
	_check(not scene.services.visible and scene.player.controls_enabled, "关闭菜单不再恢复右上角支线入口")
	await _capture("world")
	scene._open_luo()
	scene.luo_dialogue.decline_gift()
	_check(state.load_progress() and state.gift_status == "declined", "拒绝礼物即时保存")
	scene.luo_dialogue._respond("private")
	_check(not scene.dialogue_line.text.contains("你来到店门口"), "不提前展开后续会面")
	var before := [state.credits, state.inventory.duplicate(), state.invitation]
	scene.luo_dialogue.pending_business()
	_check(before == [state.credits, state.inventory, state.invitation], "后续占位不扣款或修改选择")
	state.evidence_found = true
	scene.luo_dialogue._expose()
	_check(not state.contact_ended and state.luo_exposed, "核实前段供货疑点时不应提前决裂")
	scene.luo_dialogue._respond("ended")
	scene.luo_dialogue.open()
	_check(scene.dialogue_choices.get_child(0).text.contains("情报与交易"), "旧版断联状态仍有任务交易入口")
	await _capture("luo")
	_check(state.load_progress() and state.contact_ended and state.luo_exposed, "核实记录与暂停往来选择即时保存")
	var old_volume := AudioServer.get_bus_volume_db(0)
	var old_mute := AudioServer.is_bus_mute(0)
	AudioServer.set_bus_volume_db(0, linear_to_db(0.45))
	AudioServer.set_bus_mute(0, true)
	_check(SETTINGS.save_settings() == OK, "音频设置可保存")
	AudioServer.set_bus_volume_db(0, 0)
	AudioServer.set_bus_mute(0, false)
	SETTINGS.apply_saved()
	_check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(0)), 0.45) and AudioServer.is_bus_mute(0), "设置读取实际作用于音频总线")
	AudioServer.set_bus_volume_db(0, old_volume)
	AudioServer.set_bus_mute(0, old_mute)
	scene.queue_free()
	await process_frame
	state.quest_state = state.QuestState.COMPLETE
	state.echo.accepted = true
	state.saved_location = "hangar"
	scene = load("res://scenes/expedition.tscn").instantiate()
	root.add_child(scene)
	scene._open_character()
	scene._open_luo()
	_check(scene.dialogue_line.text.contains("任务交易"), "外勤可打开支线通讯，不依赖基地初始化")
	scene._start_optional_battle("demo")
	_check(not state.battle_active and scene.location_id == "hangar", "外勤通讯不可绕过训练地点限制")
	_check(scene._manual_save() and state.load_progress() and state.saved_location == "hangar", "外勤手动保存保留区域")
	if not failed:
		print("CHARACTER_HUB_OK")
	quit(1 if failed else 0)
