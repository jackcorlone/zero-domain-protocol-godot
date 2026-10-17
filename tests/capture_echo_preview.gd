extends SceneTree

var failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state: ZeroDomainGameState = root.get_node("GameState")
	state.save_path = "/private/tmp/zero-domain-echo-preview-%d.cfg" % OS.get_process_id()
	state.reset()
	state.quest_state = state.QuestState.COMPLETE
	state.echo.accepted = true
	state.saved_location = "hangar"
	var scene: Node = load("res://scenes/expedition.tscn").instantiate()
	root.add_child(scene)
	scene.player.position = Vector2(790, 640)
	await _capture("hangar")
	scene._boarding()
	await _capture("boarding")
	scene._fly("landing")
	await _capture("flight")
	scene._finish_flight()
	await _capture("landing")
	scene._set_location("highland")
	scene.player.position = Vector2(620, 575)
	await _capture("highland")
	scene._start_puzzle("antenna")
	await _capture("puzzle")
	for action: String in ["短", "长", "短"]:
		scene._puzzle_choose(action)
	scene._close_modals()
	scene._open_modal(scene.map_panel)
	await _capture("map")
	_check(scene.map_panel.get_global_rect().end.y <= 720, "导航地图越界")
	scene._set_location("wrecksite")
	scene.player.position = Vector2(570, 510)
	await _capture("wreck")
	scene._set_location("ravine")
	scene.player.position = Vector2(965, 420)
	await _capture("ravine-before")
	scene._bridge()
	scene._start_puzzle("bridge")
	for action: String in ["接地", "供电", "搭桥"]:
		scene._puzzle_choose(action)
	scene._close_modals()
	await _capture("ravine-after")
	scene._set_location("station")
	scene.player.position = Vector2(800, 610)
	await _capture("station")
	state.echo.entry = "maintenance"
	scene._enter_archive()
	scene.player.position = Vector2(770, 530)
	await _capture("archive")
	scene._core()
	await _capture("core")
	_check(scene.dialogue_panel.get_global_rect().end.y <= 720, "档案对话越界")
	_check(state.echo.clues.size() >= 2, "档案截图必须展示实际最终剧情")
	scene._close_modals()
	scene._open_modal(scene.map_panel)
	await _capture("map-complete")
	_check(scene.map_panel.get_global_rect().end.y <= 720, "全部区域导航地图越界")
	if not failed:
		print("ECHO_PREVIEW_OK")
	quit(1 if failed else 0)


func _capture(label: String) -> void:
	for frame: int in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png("/private/tmp/zero-domain-echo-%s.png" % label) == OK, "截图失败")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
