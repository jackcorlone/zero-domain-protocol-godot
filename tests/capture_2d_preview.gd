extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("预览截图需要图形渲染，不能使用 --headless。")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var exploration: Node = load("res://scenes/exploration.tscn").instantiate()
	root.add_child(exploration)
	await _capture("exploration")
	exploration._accept_quest()
	exploration._scan_terminal()
	exploration._set_location("b7")
	await _capture("b7")
	exploration._choose_relay(ZeroDomainGameState.RelayChoice.MIRROR_SIGNAL)
	exploration._start_battle()
	await _capture("battle")
	exploration.battle_screen._perform_action("skill")
	await create_timer(0.95).timeout
	await _capture("battle-after-skill")
	exploration.battle_screen._perform_action("retreat")
	exploration._set_location("command")
	exploration._open_modal(exploration.character_panel)
	await _capture("character")
	print("PREVIEW_2D_OK")
	quit(0)


func _capture(label: String) -> void:
	for frame: int in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("/private/tmp/zero-domain-2d-%s.png" % label)
	if error != OK:
		push_error("截图保存失败：" + label)
		quit(1)
