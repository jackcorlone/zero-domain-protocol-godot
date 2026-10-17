extends SceneTree

var failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: ZeroDomainGameState = root.get_node("GameState")
	state.reset()
	state.quest_state = state.QuestState.TERMINAL_SCANNED
	change_scene_to_file("res://scenes/exploration.tscn")
	await _settle()
	current_scene._interact_command_elevator()
	_check(current_scene.dialogue_choices.get_child_count() == 3, "终端解锁后电梯应包含机甲整备舱入口")
	current_scene._enter_mech_bay()
	await _settle()
	_check(current_scene.scene_file_path == "res://scenes/mech_bay.tscn", "电梯应进入新的机甲整备舱场景")
	_check(current_scene.exhibits.size() == 4, "场景应包含三套机体和返回出口")
	_check(current_scene.player.name == "RedlineSeraphPlayer", "平地地图中应由赤线炽天作为可驾驶角色")
	_check(current_scene.player_map_sprite != null and not current_scene.player.actor_sprite.visible, "主角应使用机甲地图素材而非人形素材")
	if not ResourceLoader.exists(current_scene.REDLINE_MAP_PATH):
		_check(current_scene.player_map_sprite.sprite_frames.get_frame_texture("down", 0) == current_scene.REDLINE_SERAPH, "方向表素材未导入时应完整显示静态备用图")
	else:
		var down_frame: Texture2D = current_scene.player_map_sprite.sprite_frames.get_frame_texture("down", 0)
		var down_atlas := down_frame as AtlasTexture
		_check(down_atlas != null and down_atlas.region.size == Vector2(627, 627), "赤线炽天应按 2×2 方向表切分为 627 像素方格")
	for path: String in [current_scene.WHITE_MAP_PATH, current_scene.IRON_MAP_PATH, current_scene.REDLINE_MAP_PATH]:
		var map_texture: Texture2D = load(path)
		_check(map_texture.get_size() == Vector2(1254, 1254), "地图机体方向表应保持统一尺寸")
		_check(map_texture.get_image().get_pixel(0, 0).a < 0.01, "地图机体方向表必须保留透明背景")
	_check(current_scene.exhibits.white_aegis.node.name == "WhiteAegisSupport", "白曜神盾应作为可见的友方支援单位")
	_check(current_scene.enemy_unit.name == "IronBastionPatrol", "铁垒应作为地图巡逻敌人")
	var patrol_start: float = current_scene.enemy_unit.position.x
	current_scene._update_enemy_patrol(1.0)
	_check(current_scene.enemy_unit.position.x != patrol_start, "普通敌机应在平地地图上巡逻")
	for texture: Texture2D in [current_scene.WHITE_AEGIS, current_scene.IRON_BASTION, current_scene.REDLINE_SERAPH]:
		_check(texture.get_image().get_pixel(0, 0).a < 0.01, "三套机甲小图标必须保留透明背景")
	for id: String in current_scene.EXHIBITS:
		current_scene.player.position = current_scene.EXHIBITS[id].position
		current_scene._open_detail(id)
		_check(current_scene.detail_icon.texture == current_scene.EXHIBITS[id].texture, "机体资料应显示对应的 2D 图标")
		_check(not current_scene.player.controls_enabled and current_scene.detail_panel.visible, "查看资料时应冻结移动")
		current_scene._close_detail()
	_check(current_scene.EXHIBITS.iron_bastion.role.contains("普通敌机"), "图二机体必须明确标记为普通敌人")
	_check(current_scene.EXHIBITS.redline_seraph.role.contains("主角座驾"), "图三机体必须明确标记为主角座驾")
	current_scene._open_enemy_contact()
	_check(current_scene.detail_choices.get_child_count() == 2, "靠近敌机应提供战斗或后退入口")
	current_scene._start_patrol_encounter()
	_check(current_scene.enemy_engaged, "确认遭遇后应停止敌机巡逻")
	current_scene._end_patrol_encounter()
	_check(not current_scene.enemy_engaged and current_scene.mode == current_scene.Mode.EXPLORE, "脱离接触后应恢复地图探索")
	_check(current_scene.detail_panel.get_global_rect().end.x <= 1280 and current_scene.detail_panel.get_global_rect().end.y <= 720, "机体资料面板不能超出视口")
	current_scene._return_to_command()
	await _settle()
	_check(current_scene.scene_file_path == "res://scenes/exploration.tscn" and current_scene.location_id == "command", "机甲舱出口应返回指挥中心")
	if not failed:
		print("MECH_BAY_OK")
	quit(1 if failed else 0)


func _settle() -> void:
	for frame: int in range(4):
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
