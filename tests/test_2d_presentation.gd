extends SceneTree

var failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var exploration: Node = load("res://scenes/exploration.tscn").instantiate()
	root.add_child(exploration)
	await process_frame
	var actor: AnimatedSprite2D = exploration.player.actor_sprite
	_assert(actor.sprite_frames.get_animation_names().size() == 4, "探索应使用四方向二维角色")
	for direction: String in ["down", "left", "right", "up"]:
		_assert(actor.sprite_frames.get_frame_count(direction) == 4, "每个方向应有四个行走帧")
		var texture := actor.sprite_frames.get_frame_texture(direction, 0)
		_assert(absf(texture.get_height() * actor.scale.y - 58.0) < 1.0, "小角色的帧高度应约为58像素")
	for texture: Texture2D in [exploration.PORTRAIT, exploration.COMMANDER_ART, exploration.SENTINEL_WORLD, exploration.player.WALK_SHEET]:
		_assert(texture.get_image().get_pixel(0, 0).a < 0.01, "角色资产必须具有透明背景")
	_assert(exploration.player.get_child_count() == 2, "玩家仅保留碰撞和角色图像，不应有脚底标记")
	_assert(exploration.command_collision.collision_layer == 1 and exploration.b7_collision.collision_layer == 0, "指挥中心应只启用本地图碰撞")
	exploration.player.position = Vector2(752, 425)
	Input.action_press("move_up")
	for index: int in range(40):
		await physics_frame
	Input.action_release("move_up")
	_assert(exploration.player.position.y >= 394.0, "角色不能穿过新地图的指挥桌")
	_assert(exploration.player.position.y < 425.0, "角色应能接近指挥桌")
	_assert(exploration.player_status.text.contains("MP"), "探索状态必须显示 MP")
	exploration._accept_quest()
	exploration._scan_terminal()
	exploration._set_location("b7")
	_assert(exploration.command_collision.collision_layer == 0 and exploration.b7_collision.collision_layer == 1, "切换地图应同步切换碰撞")
	exploration._choose_relay(ZeroDomainGameState.RelayChoice.MIRROR_SIGNAL)
	exploration._start_battle()
	await process_frame
	var battle: ZeroDomainBattleScreen = exploration.battle_screen
	_assert(battle.player_art.position.x > 720 and battle.player_art.size.y > 640, "战斗立绘应占据右侧大幅区域")
	_assert(battle.player_art.get_global_rect().end.x <= 1280 and battle.player_art.get_global_rect().end.y <= 720, "战斗立绘不能因原图尺寸超出画面")
	for child: Node in battle.root.get_children():
		if child is TextureRect:
			_assert(child.get_global_rect().end.x <= 1280 and child.get_global_rect().end.y <= 720, "战斗图像应按布局缩放而非原始像素大小展示")
	_assert(battle.player_mp_bar.value == exploration.game_state.energy, "蓝条必须使用实际 MP")
	for button: Button in battle.action_buttons:
		_assert(button.get_global_rect().end.x <= 1280 and button.get_global_rect().end.y <= 720, "指令按钮不能超出视口")
	if not failed:
		print("PRESENTATION_2D_OK")
	quit(1 if failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
