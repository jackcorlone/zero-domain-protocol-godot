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
	var menu: Node = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	await _capture("menu")
	menu.queue_free()
	await process_frame
	var scene: Node = load("res://scenes/exploration.tscn").instantiate()
	root.add_child(scene)
	await _capture("exploration")
	scene.luo_dialogue.open()
	await _capture("luo")
	_check(scene.dialogue_panel.get_global_rect().end.y <= 720, "罗老板对话越界")
	scene.luo_dialogue.accept_gift()
	scene.game_state.equip_armor("redline")
	scene.game_state.health = 300
	scene._open_character()
	await _capture("character")
	_check(scene.character_panel.get_global_rect().end.x <= 1280 and scene.character_panel.get_global_rect().end.y <= 720, "人物面板越界")
	scene._start_optional_battle("practice")
	await _capture("battle")
	_check(scene.battle_screen.player_status_label.get_global_rect().end.y <= 720, "战斗状态越界")
	_check(scene.battle_screen.combat_log.get_global_rect().end.y <= 720, "战斗日志越界")
	scene.battle_screen._perform_action("items")
	await _capture("items")
	scene.battle_screen.choice_panel.hide()
	scene.game_state.energy = 71
	scene.battle_screen._perform_action("skill")
	await _capture("mp-confirm")
	scene.battle_screen.boost_confirmation.hide()
	scene.battle_screen._perform_action("retreat")
	scene._accept_quest()
	scene._scan_terminal()
	scene._set_location("b7")
	scene._choose_relay(ZeroDomainGameState.RelayChoice.MIRROR_SIGNAL)
	scene._start_battle()
	scene.battle_screen.enemy_health = 0
	scene.battle_screen._finish_victory()
	await create_timer(0.95).timeout
	scene._interact_wreck()
	scene._set_location("command")
	scene._report_to_commander()
	await _capture("quest-report")
	_check(scene.dialogue_panel.get_global_rect().end.y <= 720, "主线长对话越界")
	if not failed:
		print("REDLINE_PREVIEW_OK")
	quit(1 if failed else 0)


func _capture(label: String) -> void:
	for frame: int in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("/private/tmp/zero-domain-redline-%s.png" % label)
	_check(result == OK, "截图保存失败")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
