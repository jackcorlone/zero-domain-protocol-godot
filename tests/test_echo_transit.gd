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


func _run() -> void:
	var state: ZeroDomainGameState = root.get_node("GameState")
	state.reset()
	state.save_path = "/private/tmp/zero-domain-echo-transit-%d.cfg" % OS.get_process_id()
	state.persistence_enabled = true
	state.quest_state = state.QuestState.COMPLETE
	change_scene_to_file("res://scenes/exploration.tscn")
	await _settle()
	current_scene._expedition_briefing()
	_check(not state.echo.accepted, "查看简报不能自动接任务")
	current_scene._accept_expedition()
	current_scene._interact_command_elevator()
	_check(current_scene.dialogue_choices.get_child_count() == 4, "保留B7、返回和机甲舱选项，新增H1")
	current_scene._enter_hangar()
	await _settle()
	_check(current_scene.scene_file_path == "res://scenes/expedition.tscn" and current_scene.location_id == "hangar", "基地电梯应实际切换至机库")
	current_scene._fly("landing")
	current_scene._finish_flight()
	current_scene._travel("highland")
	current_scene._download_antenna()
	current_scene._travel("wrecksite")
	current_scene._manifest()
	current_scene._travel("station")
	current_scene._start_puzzle("maintenance")
	for action: String in ["旁路", "验压", "开舱"]:
		current_scene._puzzle_choose(action)
	current_scene._enter_archive()
	_check(state.saved_location == "archive" and state.save_progress() == OK, "档案室进度可保存")
	change_scene_to_file("res://scenes/main_menu.tscn")
	await _settle()
	current_scene._continue_game()
	await _settle()
	_check(current_scene.location_id == "archive" and state.echo.clues.size() == 2, "主菜单继续应恢复外勤位置与线索")
	current_scene._resolve_outcome("keep")
	current_scene._travel("station")
	current_scene._travel("highland")
	current_scene._travel("landing")
	current_scene._fly("hangar")
	current_scene._finish_flight()
	current_scene._return_base()
	await _settle()
	_check(current_scene.scene_file_path == "res://scenes/exploration.tscn" and current_scene.location_id == "command", "返航电梯应实际返回基地")
	var credits_before: int = state.credits
	current_scene._expedition_briefing()
	current_scene._report_expedition()
	current_scene._report_expedition()
	_check(state.echo.reward_claimed and state.credits == credits_before + 300, "基地汇报一次领奖并保存")
	_check(state.load_progress() and state.echo.reward_claimed and state.echo.outcome == "keep", "任务处置和奖励可读取")
	current_scene._enter_hangar()
	await _settle()
	current_scene._fly("landing")
	current_scene._finish_flight()
	_check(state.echo.outcome == "keep", "结算后仍可重返盆地")
	if not failed:
		print("ECHO_TRANSIT_OK")
	quit(1 if failed else 0)
