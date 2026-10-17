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
	var scene: Node = load("res://scenes/mech_bay.tscn").instantiate()
	root.add_child(scene)
	await _capture("mech-yard-v2")
	scene._open_detail("redline_seraph")
	await _capture("mech-yard-contact-v2")
	print("MECH_PREVIEW_OK")
	quit(0)


func _capture(label: String) -> void:
	for frame: int in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://docs/previews/%s.png" % label)
	if error != OK:
		push_error("截图保存失败：" + label)
		quit(1)
