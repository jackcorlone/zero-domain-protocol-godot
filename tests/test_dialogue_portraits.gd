extends SceneTree

var failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var state: ZeroDomainGameState = root.get_node("GameState")
	state.reset()
	state.persistence_enabled = false
	var scene: Node = load("res://scenes/exploration.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	scene._show_dialogue("基地指挥官 / COMMANDER", "沈砚", "布局检查。")
	_check(scene.dialogue_avatar_frame.visible, "沈砚对话应显示小头像")
	_check(scene.dialogue_avatar.texture is AtlasTexture and scene.dialogue_avatar.texture.atlas == scene.COMMANDER_ART, "沈砚应自动映射指挥官头像切片")
	_check(scene.dialogue_portrait.visible, "有角色资源时应显示侧边立绘")
	_check(scene.dialogue_panel.get_global_rect().end.y <= 720, "增加头像后对话框不得越界")

	scene._show_dialogue("安全终端 / SECURE TERMINAL", "B7-7A 最终记录", "系统记录。")
	_check(not scene.dialogue_avatar_frame.visible, "终端说话者必须隐藏人物头像")
	_check(not scene.dialogue_portrait.visible, "终端说话者必须隐藏侧边立绘")
	_check(scene.dialogue_avatar.texture == null, "切换至系统对话时不得残留上一角色资源")

	scene._show_dialogue("任务通讯", "凌霁 · LYRA-7", "人物映射检查。")
	_check(scene.dialogue_avatar_frame.visible and scene.dialogue_avatar.texture != null, "凌霁对话应自动使用当前角色立绘")
	state.mi_po.met = true
	for trust: int in [0, 30, 80]:
		state.mi_po.trust = trust
		scene._show_dialogue("为活者调弦", "弥珀", "信赖差分检查。")
		var avatar := scene.dialogue_avatar.texture as AtlasTexture
		_check(scene.dialogue_portrait.texture == scene.MI_PO_ART, "弥珀对话应显示全身立绘")
		_check(avatar != null and avatar.atlas == scene.MI_PO_PORTRAITS and avatar.region.position.x == (trust / 30 if trust < 80 else 2) * 724, "弥珀小头像应随0/30/80信赖切换")
	scene._add_dialogue_choice("继续", scene._close_modals)
	_check(scene.dialogue_choices.get_child_count() == 1, "头像布局不得破坏对话选项")
	scene._close_modals()
	_check(not scene.dialogue_panel.visible and scene.mode == scene.Mode.EXPLORE, "ESC 共用的关闭逻辑保持不变")
	_check(not scene.dialogue_portrait.visible, "关闭对话时必须一并隐藏侧边立绘")

	scene.queue_free()
	await process_frame
	if failed:
		quit(1)
	else:
		print("DIALOGUE_PORTRAITS_OK")
		quit(0)
