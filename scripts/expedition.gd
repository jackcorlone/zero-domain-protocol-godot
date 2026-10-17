extends "res://scripts/exploration.gd"

const MAPS := preload("res://scripts/expedition_maps.gd")
const VOYAGE_ENCOUNTERS := preload("res://scripts/voyage_encounters.gd")
const ECLIPSE_CARRIER_CG := preload("res://assets/story/eclipse-carrier-ruins-v1.png")
var map_objects: Node2D
var camera: Camera2D
var points: Dictionary = {}
var flight_destination: String = ""
var flight_panel: ColorRect
var flight_title: Label
var flight_progress: ProgressBar
var flight_tween: Tween
var map_text: Label
var current_puzzle: String = ""
var puzzle_progress: int = 0
var patrol: Node2D
var bridge_blocker: StaticBody2D
var bridge_deck: Node2D
var guard: Node2D
var last_encounter: String = ""
var patrol_clock: float = 0.0
var objective_guide: Label
var mi_po_custody_choice: String = ""


func _ready() -> void:
	if not game_state.echo.accepted or game_state.quest_state != ZeroDomainGameState.QuestState.COMPLETE:
		game_state.saved_location = "command"
		get_tree().call_deferred("change_scene_to_file", "res://scenes/exploration.tscn")
		return
	_build_background()
	_build_world()
	_build_hud()
	_build_battle()
	_build_flight()
	_set_location(game_state.saved_location if game_state.saved_location in MAPS.NAMES else "hangar")


func _build_background() -> void:
	background = TextureRect.new()
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.size = MAPS.SIZE
	background.z_index = -20
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	world_shade = ColorRect.new()
	world_shade.size = MAPS.SIZE
	world_shade.color = Color(0.02, 0.05, 0.1, 0.02)
	world_shade.z_index = -19
	world_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(world_shade)


func _build_world() -> void:
	y_sort_enabled = true
	map_objects = Node2D.new()
	map_objects.y_sort_enabled = true
	add_child(map_objects)
	player = CharacterBody2D.new()
	player.set_script(PLAYER_SCRIPT)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 9
	collision.shape = shape
	player.add_child(collision)
	add_child(player)
	player.movement_bounds = Rect2(70, 70, 1396, 884)
	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1536
	camera.limit_bottom = 1024
	player.add_child(camera)
	camera.make_current()


func _set_location(next_location: String) -> void:
	if next_location not in MAPS.NAMES:
		return
	_close_modals()
	location_id = next_location
	services.hide()
	for node: Node in map_objects.get_children():
		map_objects.remove_child(node)
		node.queue_free()
	points.clear()
	patrol = null
	guard = null
	bridge_blocker = null
	bridge_deck = null
	var image_path: String = "res://assets/environments/" + MAPS.IMAGES[location_id]
	background.texture = load(image_path)
	player.position = MAPS.SPAWNS[location_id]
	player.movement_bounds = Rect2(165, 180, 1205, 675) if location_id == "archive" else (Rect2(95, 120, 1340, 795) if location_id == "hangar" else Rect2(70, 70, 1396, 884))
	camera.reset_smoothing()
	if location_id in game_state.VOYAGE_LOCATIONS:
		if location_id not in game_state.voyage.visited:
			game_state.voyage.visited.append(location_id)
	elif location_id in game_state.RUIN_LOCATIONS:
		if location_id not in game_state.ruins.visited:
			game_state.ruins.visited.append(location_id)
	elif location_id not in game_state.echo.visited:
		game_state.echo.visited.append(location_id)
	var obstacles: Array[Rect2] = []
	obstacles.assign(MAPS.OBSTACLES[location_id])
	var collision := _map_collision(obstacles)
	remove_child(collision)
	map_objects.add_child(collision)
	_build_points()
	_refresh_world()
	_update_hud()


func _build_points() -> void:
	match location_id:
		"hangar":
			_point("base", "电梯 · 返回指挥中心", Vector2(342, 695), _return_base)
			_point("boarding", "游隼 · 登舰", Vector2(790, 550), _boarding)
			_point("engineer", "岑遥 · 航行工程员", Vector2(1220, 565), _engineer, load("res://assets/npcs/echo-engineer-v1.png"))
			_point("supplies", "整备柜", Vector2(1160, 815), _open_shop)
			_exit("ballroom", Vector2(1040, 850))
		"ballroom":
			_point("wardrobe", "星环衣装室", Vector2(355, 590), _gala_wardrobe)
			_point("hostess", "温澜 · 基金会理事", Vector2(600, 430), _gala_hostess)
			_point("performance", "星辉舞台", Vector2(770, 310), _gala_stage)
			_point("broker", "顾迢 · 装备经纪人", Vector2(1100, 500), _gala_broker)
			_point("lounge", "观星休息区", Vector2(1040, 760), _gala_lounge)
			_exit("hangar", Vector2(770, 900))
		"landing":
			_point("boarding", "游隼 · 返航", Vector2(500, 465), _boarding)
			_exit("highland", Vector2(780, 110))
			_exit("wrecksite", Vector2(1410, 490))
			_exit("ravine", Vector2(1050, 805))
			if game_state.echo.rescued:
				_point("survivor", "获救维修员", Vector2(635, 475), _survivor, COMMANDER_ART)
		"highland":
			_point("antenna", "天线控制箱", Vector2(545, 540), _antenna)
			_exit("landing", Vector2(820, 910))
			_exit("wrecksite", Vector2(1410, 540))
			_exit("station", Vector2(785, 110))
			patrol = _point("patrol", "受信标引导的巡逻机", Vector2(1050, 570), _patrol_dialogue, SENTINEL_WORLD)
		"wrecksite":
			_point("manifest", "货舱 · 运输单", Vector2(405, 275), _manifest)
			_point("rescue", "生存舱 · 求救声", Vector2(560, 455), _rescue)
			_exit("landing", Vector2(110, 565))
			_exit("highland", Vector2(800, 115))
			_exit("ravine", Vector2(1410, 530))
			_exit("station", Vector2(1340, 340))
		"ravine":
			_point("bridge", "断桥控制箱", Vector2(965, 375), _bridge)
			_point("cache", "封存的测绘箱", Vector2(1230, 150), _cache)
			_exit("wrecksite", Vector2(260, 520))
			_exit("station", Vector2(1380, 500))
			_exit("landing", Vector2(800, 910))
			_point("shortcut", "着陆点 · 高架捷径", Vector2(460, 295), _shortcut)
			bridge_blocker = _map_collision([Rect2(745, 243, 60, 92)])
			remove_child(bridge_blocker)
			map_objects.add_child(bridge_blocker)
			bridge_deck = Node2D.new()
			bridge_deck.z_index = -5
			map_objects.add_child(bridge_deck)
			for index: int in range(7):
				var plank := Polygon2D.new()
				plank.polygon = PackedVector2Array([Vector2(738, 247 + index * 12), Vector2(815, 247 + index * 12), Vector2(815, 257 + index * 12), Vector2(738, 257 + index * 12)])
				plank.color = Color("aeb9bf") if index % 2 == 0 else Color("6f8997")
				bridge_deck.add_child(plank)
		"station":
			guard = _point("guard", "正门 · 守卫", Vector2(875, 530), _gate, SENTINEL_WORLD)
			_point("maintenance", "外墙 · 检修标记", Vector2(520, 500), _maintenance)
			_point("permit", "身份协商终端", Vector2(1070, 520), _permit)
			_point("door", "观测站 · 进入档案室", Vector2(785, 550), _enter_archive)
			_exit("highland", Vector2(130, 580))
			_exit("wrecksite", Vector2(780, 910))
			_exit("ravine", Vector2(1400, 605))
		"archive":
			_point("core", "档案主控台", Vector2(770, 460), _core)
			_exit("station", Vector2(770, 845))
		"ruined_village":
			_point("boarding", "游隼 · 返航", Vector2(500, 770), _boarding)
			_point("shelter", "温室避难所 · 生命信号", Vector2(610, 600), _ruins_shelter)
			_point("crater", "航母钻击坑", Vector2(365, 355), _ruins_crater)
			_point("memorial", "村口纪念塔", Vector2(780, 550), _ruins_memorial)
			_point("observatory", "倒塌的观测台", Vector2(1160, 390), _ruins_observatory)
			_exit("ruin_vault", Vector2(1270, 760))
		"ruin_vault":
			_point("phase_core", "星核相位库", Vector2(770, 460), _phase_core)
			if game_state.ruins.shelter_secured:
				_point("mi_po", "弥珀 · 共振档案师", Vector2(1110, 560), _mi_po, MI_PO_ART)
			if game_state.mi_po.met:
				_point("archive_clock", "档案时钟", Vector2(380, 520), _mi_po_clock)
				_point("pulse_console", "生命频谱台", Vector2(560, 690), _mi_po_pulse)
			if game_state.mi_po.trust >= 30 and game_state.ruins.secret_recovered and not game_state.mi_po.quest_complete:
				_point("resonance_node", "档案库共振节点", Vector2(980, 700), _mi_po_resonance_node.bind("vault", "档案库"))
			_exit("ruined_village", Vector2(770, 845))
		"starport":
			_point("he_cen", "贺岑 · 航务主管", Vector2(470, 520), _he_cen, VOYAGE_ENCOUNTERS.npc_texture(Rect2(0, 0, 760, 1024)))
			_point("qi_wu", "祁雾 · 检疫工程师", Vector2(1060, 520), _qi_wu, VOYAGE_ENCOUNTERS.npc_texture(Rect2(700, 0, 836, 1024)))
			_point("boarding", "游隼 · 前往涅柔斯-4", Vector2(760, 330), _boarding)
			_point("base", "电梯 · 返回飞船舱", Vector2(760, 900), _fly.bind("hangar"))
		"tentacle_field", "eldritch_ruins", "storm_sea":
			var positions: Array[Vector2] = [Vector2(390, 430), Vector2(790, 330), Vector2(1160, 520)]
			var enemy_ids: Array = VOYAGE_ENCOUNTERS.MAP_ENEMIES[location_id]
			for index: int in enemy_ids.size():
				var enemy_id: String = enemy_ids[index]
				var data: Dictionary = VOYAGE_ENCOUNTERS.config(enemy_id)
				_point(enemy_id, str(data.name), positions[index], _voyage_enemy.bind(enemy_id), VOYAGE_ENCOUNTERS.texture(enemy_id))
			if location_id == "tentacle_field":
				_point("boarding", "游隼 · 返回 H1 星港", Vector2(560, 850), _boarding)
			for destination: String in MAPS.LINKS[location_id]:
				_exit(destination, Vector2(1380, 820) if destination != "tentacle_field" else Vector2(150, 820))


func _point(id: String, title: String, position_value: Vector2, callback: Callable, texture: Texture2D = null) -> Node2D:
	var node := _marker(title, position_value, Color("90ecdf"))
	var label := node.get_child(0) as Label
	label.position = Vector2(-125, -65)
	label.size = Vector2(250, 30)
	label.add_theme_color_override("font_color", Color("e9fffb"))
	label.add_theme_color_override("font_outline_color", Color("173746"))
	map_objects.add_child(node)
	if texture != null:
		var actor := Sprite2D.new()
		actor.texture = texture
		actor.position.y = -25
		actor.scale = Vector2.ONE * (58.0 / texture.get_height())
		node.add_child(actor)
	var badge := _label("!", 30, Color("ffd35a"))
	badge.name = "QuestBadge"
	badge.position = Vector2(-14, -112 if texture != null else -88)
	badge.size = Vector2(28, 36)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_color_override("font_outline_color", Color("402c09"))
	badge.add_theme_constant_override("outline_size", 6)
	badge.hide()
	node.add_child(badge)
	points[id] = {"node": node, "callback": callback, "title": title}
	return node


func _exit(destination: String, position_value: Vector2) -> void:
	_point("exit_" + destination, "→ " + MAPS.NAMES[destination], position_value, _travel.bind(destination))


func _travel(destination: String) -> void:
	if destination not in MAPS.LINKS[location_id]:
		return
	_set_location(destination)


func _process(delta: float) -> void:
	if not is_instance_valid(player) or mode != Mode.EXPLORE or flight_destination != "":
		return
	patrol_clock += delta
	var objective_id := _objective_point_id()
	for id: String in points:
		var marker: Node2D = points[id].node
		marker.get_child(0).visible = id == objective_id or id.begins_with("exit_") or player.position.distance_to(marker.position) < 260.0 or (game_state.echo.survey_module and id == "cache")
		var badge := marker.get_node("QuestBadge") as Label
		badge.visible = id == objective_id
	if is_instance_valid(patrol) and patrol.visible:
		patrol.position = Vector2(1020 + sin(patrol_clock * 0.6) * 85, 580 + cos(patrol_clock * 0.6) * 35)
	var target := _nearest_target()
	interaction_tip.text = "[ E ] " + str(points[target].title) if target != "" else "探索路口与设施 · E 交互 · M 地图"
	_update_objective_guide(objective_id)


func _build_hud() -> void:
	super._build_hud()
	objective_guide = _label("", 17, Color("fff2b0"))
	objective_guide.position = Vector2(430, 24)
	objective_guide.size = Vector2(700, 42)
	objective_guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_guide.add_theme_color_override("font_outline_color", Color("17242c"))
	objective_guide.add_theme_constant_override("outline_size", 6)
	objective_guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var layer := CanvasLayer.new()
	layer.layer = 25
	add_child(layer)
	layer.add_child(objective_guide)


func _objective_point_id() -> String:
	if location_id == "ballroom":
		if not game_state.gala.networked:
			return "hostess"
		if not game_state.gala.performed:
			return "wardrobe"
		if not game_state.gala.resonator:
			return "broker"
		return "exit_hangar"
	if location_id in game_state.VOYAGE_LOCATIONS:
		if location_id == "starport":
			if game_state.voyage.module_choice == "":
				return "he_cen"
			if game_state.voyage.sprays == 0:
				return "qi_wu"
			return "boarding"
		for enemy_id: String in VOYAGE_ENCOUNTERS.MAP_ENEMIES[location_id]:
			if enemy_id not in game_state.voyage.defeated:
				return enemy_id
		return "boarding" if points.has("boarding") else _first_exit_toward(MAPS.LINKS[location_id][0])
	if location_id == "ruined_village":
		if not game_state.ruins.shelter_secured:
			return "shelter"
		if game_state.mi_po.met and not game_state.mi_po.nameplates_placed:
			return "memorial"
		if game_state.mi_po.nameplates_placed and not game_state.mi_po.memorial_returned:
			return "exit_ruin_vault"
		if game_state.ruins.secret_recovered:
			if game_state.mi_po.trust >= 30 and not game_state.mi_po.quest_complete:
				if game_state.mi_po.resonance_nodes.get("crater", "") != "inverse":
					return "crater"
				if game_state.mi_po.resonance_nodes.get("observatory", "") != "silent":
					return "observatory"
				return "exit_ruin_vault"
			return "boarding"
		for clue: String in ["crater", "memorial", "observatory"]:
			if clue not in game_state.ruins.clues:
				return clue
		return "exit_ruin_vault"
	if location_id == "ruin_vault":
		if game_state.ruins.shelter_secured and not game_state.mi_po.met:
			return "mi_po"
		if game_state.mi_po.met and not game_state.mi_po.clock_restored:
			return "archive_clock"
		if game_state.mi_po.met and not game_state.mi_po.pulse_verified:
			return "pulse_console"
		if game_state.mi_po.nameplates_placed and not game_state.mi_po.memorial_returned:
			return "mi_po"
		if game_state.mi_po.met and not game_state.mi_po.memorial_returned:
			return "exit_ruined_village"
		if game_state.mi_po.trust >= 30 and game_state.ruins.secret_recovered and not game_state.mi_po.quest_complete:
			if game_state.mi_po.resonance_nodes.get("crater", "") != "inverse" or game_state.mi_po.resonance_nodes.get("observatory", "") != "silent":
				return "exit_ruined_village"
			if game_state.mi_po.resonance_nodes.get("vault", "") != "positive":
				return "resonance_node"
			return "mi_po"
		return "exit_ruined_village" if game_state.ruins.secret_recovered else "phase_core"
	if location_id == "hangar":
		return "base" if game_state.echo.outcome != "" or game_state.ruins.secret_recovered else "boarding"
	if game_state.echo.outcome != "":
		return "boarding" if points.has("boarding") else _first_exit_toward("landing")
	if location_id == "archive":
		return "core"
	if game_state.echo.clues.size() >= 2:
		return "door" if location_id == "station" else _first_exit_toward("station")
	for candidate: String in ["antenna", "manifest", "bridge"]:
		if points.has(candidate):
			return candidate
	return "boarding" if points.has("boarding") else ""


func _first_exit_toward(destination: String) -> String:
	var direct := "exit_" + destination
	if points.has(direct):
		return direct
	for id: String in points:
		if id.begins_with("exit_"):
			return id
	return ""


func _update_objective_guide(objective_id: String) -> void:
	if not is_instance_valid(objective_guide) or objective_id.is_empty() or not points.has(objective_id):
		if is_instance_valid(objective_guide):
			objective_guide.text = ""
		return
	var target: Node2D = points[objective_id].node
	var offset := target.global_position - player.global_position
	var arrow := "→" if absf(offset.x) >= absf(offset.y) and offset.x >= 0.0 else ("←" if absf(offset.x) >= absf(offset.y) else ("↓" if offset.y >= 0.0 else "↑"))
	objective_guide.text = "任务目标 %s  %dm · %s" % [arrow, roundi(offset.length() / 10.0), points[objective_id].title]


func _nearest_target() -> String:
	var nearest := ""
	var distance := 98.0
	for id: String in points:
		var node: Node2D = points[id].node
		var candidate := player.position.distance_to(node.position)
		if node.visible and candidate < distance:
			nearest = id
			distance = candidate
	return nearest


func _interact_with_nearest() -> void:
	var id := _nearest_target()
	if id != "":
		points[id].callback.call()


func _unhandled_input(event: InputEvent) -> void:
	if flight_destination != "":
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			_finish_flight()
		return
	super._unhandled_input(event)


func _update_hud() -> void:
	# Reuse equipment/HP/MP widgets, then replace only the expedition-specific text.
	super._update_hud()
	if location_id == "ballroom":
		location_label.text = "SITE OMEGA / 舰内社交区\n" + MAPS.NAMES[location_id]
		mission_title.text = "星环夜宴"
		mission_text.text = "自由交流、休息或登台表演 · 影响力 %d/3" % game_state.gala.influence
		_update_map_text()
		return
	if location_id in game_state.VOYAGE_LOCATIONS:
		location_label.text = "涅柔斯-4 / 潮汐盲区\n" + MAPS.NAMES[location_id]
		mission_title.text = "潮讯深潜"
		mission_text.text = "在星港完成整备并登舰。" if location_id == "starport" else "清理区域威胁 · 已击败 %d/9" % game_state.voyage.defeated.size()
		_update_map_text()
		return
	if location_id in game_state.RUIN_LOCATIONS:
		location_label.text = "SABLE-3 / 灾后勘探区\n" + MAPS.NAMES[location_id]
		mission_title.text = "灰烬遗言"
		if not game_state.ruins.shelter_secured:
			mission_text.text = "先稳定温室避难所的八个生命信号。"
		elif game_state.mi_po.met and game_state.mi_po.trust < 30:
			mission_text.text = "为活者调弦 · 真实性校验 %d/3" % [int(game_state.mi_po.clock_restored) + int(game_state.mi_po.pulse_verified) + int(game_state.mi_po.memorial_returned)]
		elif game_state.ruins.secret_recovered and game_state.mi_po.trust >= 30 and not game_state.mi_po.quest_complete:
			mission_text.text = "为活者调弦 · 生活档案共振节点 %d/3" % game_state.mi_po.resonance_nodes.size()
		elif game_state.ruins.secret_recovered:
			mission_text.text = "返回游隼，向沈砚提交星核相位逆演。"
		elif game_state.ruins.clues.size() < 2:
			mission_text.text = "调查余烬村残迹 · 线索 %d/2" % game_state.ruins.clues.size()
		else:
			mission_text.text = "前往星核祭库，重建反制相位序列。"
		_update_map_text()
		return
	location_label.text = "ECHO-9 / 外勤区域\n" + MAPS.NAMES[location_id]
	mission_title.text = "回声之外"
	if game_state.echo.outcome != "":
		mission_text.text = "返回飞船，返航向沈砚汇报。" if not game_state.echo.reward_claimed else "外勤已结算，可继续自由调查。"
	elif location_id == "hangar":
		mission_text.text = "走到游隼舷梯，按 E 登舰。"
	elif game_state.echo.clues.size() < 2:
		mission_text.text = "自由调查三条支路 · 定位线索 %d/2" % game_state.echo.clues.size()
	elif location_id == "archive":
		mission_text.text = "读取档案主控台，决定如何处置信标。"
	else:
		mission_text.text = "坐标已确定，寻找观测站的入口。"
	_update_map_text()


func _refresh_world() -> void:
	for enemy_id: String in VOYAGE_ENCOUNTERS.ENEMIES:
		if points.has(enemy_id):
			points[enemy_id].node.visible = enemy_id not in game_state.voyage.defeated
	if is_instance_valid(patrol):
		patrol.visible = game_state.echo.beacon_on and not game_state.echo.patrol_down and game_state.echo.outcome != "shutdown"
	if is_instance_valid(guard):
		guard.visible = not game_state.echo.guard_down and game_state.echo.outcome != "shutdown"
	if is_instance_valid(bridge_blocker):
		bridge_blocker.collision_layer = 0 if game_state.echo.bridge_fixed else 1
		bridge_deck.visible = game_state.echo.bridge_fixed
	if points.has("rescue"):
		points.rescue.node.visible = not game_state.echo.rescued
	if points.has("cache") and game_state.echo.cache_claimed:
		points.cache.node.get_child(0).text = "测绘箱 · 已回收"
	if points.has("antenna") and game_state.echo.beacon_on:
		points.antenna.node.get_child(0).text = "灯标在线 · 道路已标记"


func _show_message(title: String, text: String) -> void:
	var header := "H1 / 星环夜宴" if location_id == "ballroom" else ("涅柔斯-4 / 潮汐盲区" if location_id in game_state.VOYAGE_LOCATIONS else ("SABLE-3 / 余烬村" if location_id in game_state.RUIN_LOCATIONS else "ECHO-9 / 回声之外"))
	_show_dialogue(header, title, text)


func _build_map_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(270, 110)
	panel.size = Vector2(740, 500)
	panel.add_theme_stylebox_override("panel", _box(Color("0b1824"), Color("32e6db"), 1, 8))
	var body := VBoxContainer.new()
	panel.add_child(body)
	body.add_child(_label("ECHO-9 / FIELD NAVIGATION", 18, Color("64eee5")))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 350
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	map_text = _label("", 18, Color("d8e8ed"))
	map_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(map_text)
	body.add_child(_label("道路连通，可原路返回。靠近路口按 E，地图不能远程传送。\nC 角色 / M 或 ESC 关闭", 14, Color("90abae")))
	panel.hide()
	return panel


func _update_map_text() -> void:
	if location_id == "ballroom":
		map_text.text = "当前：H1 · 星环舞厅\n\n衣装：%s\n社交影响力：%d/3\n名流交流：%s\n舞台演出：%s\n航运情报：%s\n星环偏导器：%s\n\n所有消费与回报都会在确认前明确显示；任何邀约均可拒绝。" % ["黑白高定晚礼服" if game_state.gala.outfit == "evening" else "白银星辉舞者服", game_state.gala.influence, "完成" if game_state.gala.networked else "未完成", "完成" if game_state.gala.performed else "未完成", "已取得" if game_state.gala.intel else "未取得", "已装备" if game_state.gala.resonator else "未取得"]
		return
	if location_id in game_state.VOYAGE_LOCATIONS:
		var voyage_text := "当前：%s\n\n已发现区域：\n" % MAPS.NAMES[location_id]
		for place: String in game_state.voyage.visited:
			voyage_text += "  " + MAPS.NAMES[place] + "\n"
		voyage_text += "\n敌情清除 %d/9    抗黏附喷剂 ×%d\n回收材料：" % [game_state.voyage.defeated.size(), game_state.voyage.sprays]
		for material: String in game_state.voyage.materials:
			voyage_text += "  %s ×%d" % [material, game_state.voyage.materials[material]]
		map_text.text = voyage_text
		return
	if location_id in game_state.RUIN_LOCATIONS:
		var ruin_text := "当前：%s\n\n已发现区域：\n" % MAPS.NAMES[location_id]
		for place: String in game_state.ruins.visited:
			ruin_text += "  " + MAPS.NAMES[place] + "\n"
		ruin_text += "\n当前道路："
		for place: String in MAPS.LINKS[location_id]:
			ruin_text += "  " + MAPS.NAMES[place]
		ruin_text += "\n\n调查记录 %d/3（任取2份即可逆演）   归潮协议：%s" % [game_state.ruins.clues.size(), "已回收" if game_state.ruins.secret_recovered else "未完成"]
		if game_state.mi_po.met:
			ruin_text += "\n弥珀信赖：%d   校验：%d/3   生活档案：%s" % [game_state.mi_po.trust, int(game_state.mi_po.clock_restored) + int(game_state.mi_po.pulse_verified) + int(game_state.mi_po.memorial_returned), "已转运" if game_state.mi_po.quest_complete else "待处理"]
		map_text.text = ruin_text
		return
	var text := "当前：%s\n\n已发现区域：\n" % MAPS.NAMES[location_id]
	for place: String in game_state.echo.visited:
		text += "  " + MAPS.NAMES[place] + "\n"
	text += "\n当前位置道路："
	for place: String in MAPS.LINKS[location_id]:
		text += "  " + MAPS.NAMES[place]
	if game_state.echo.beacon_on or game_state.echo.survey_module:
		text += "\n灯标导航：着陆点 ↔ 高地 / 货船 / 栈道\n高地、货船、栈道均可抵达观测站。\n栈道北端有测绘箱；修桥可开启高架捷径。"
	text += "\n\n线索 %d/3   救援：%s   断桥：%s" % [game_state.echo.clues.size(), "已完成" if game_state.echo.rescued else "未完成", "已修复" if game_state.echo.bridge_fixed else "未修复"]
	map_text.text = text


func _return_base() -> void:
	game_state.saved_location = "command"
	game_state.save_progress()
	get_tree().change_scene_to_file("res://scenes/exploration.tscn")


func _engineer() -> void:
	_show_message("岑遥 · 航行工程员", "下面的电磁雾会吃掉远程导航。游隼能保住落点，进盆地以后要靠你认路。\n高地、货船、栈道任意两处的记录可以交叉定位。没电也别慌，旧设施都有手动检修口。")
	_add_dialogue_choice("再次确认风险", func() -> void:
		_show_message("岑遥", "别把每台机器人都当成必须消灭的目标。灯标会暴露位置；正门守卫可以绕过。\n想整备就回着陆点，返航不收燃料费，调查进度会保留。"))
	_add_dialogue_choice("打开装备面板", _open_character)


func _gala_wardrobe() -> void:
	_show_message("星环衣装室", "两套礼仪衣装已完成身份绑定。更换只影响舞厅立绘与社交选项，不改变战斗护甲。")
	_add_dialogue_choice("换上黑白高定晚礼服 · 黑色蕾丝袜", _set_gala_outfit.bind("evening"))
	_add_dialogue_choice("换上白银星辉舞者服 · 白色高亮丝袜", _set_gala_outfit.bind("dancer"))
	_add_dialogue_choice("保持当前衣装", _close_modals)


func _set_gala_outfit(outfit: String) -> void:
	if not game_state.set_gala_outfit(outfit):
		return
	var title := "黑白高定晚礼服" if outfit == "evening" else "白银星辉舞者服"
	var art: Texture2D = load("res://assets/characters/lyra-evening-gown-v1.png" if outfit == "evening" else "res://assets/characters/lyra-gala-dancer-v1.png")
	_show_message("凌霁 · " + title, "凌霁整理好衣装，神态从容。今晚可以只是放松，也可以主动进入名流的情报交换圈。")
	_show_story_picture(art)
	_add_dialogue_choice("进入舞厅", _close_modals)
	_update_hud()


func _gala_hostess() -> void:
	if game_state.gala.networked:
		_show_message("温澜 · 基金会理事", "你的名字已经进入公开合作名单。没有附加私人邀约，也不会再次收取赞助。")
		return
	_show_message("温澜 · 基金会理事", "公开赞助席需要 100 CR。作为交换，我会把你引荐给三家航运机构，并开放一份训练档案：获得 120 EXP 与 1 点社交影响力。你可以拒绝。")
	_add_dialogue_choice("支付 100 CR · 公开交流", _gala_network)
	_add_dialogue_choice("婉拒，继续自由活动", _close_modals)


func _gala_network() -> void:
	if game_state.gala_network():
		_show_message("公开交流完成", "凌霁没有许下私人承诺，只交换了可核验的外勤经验。获得 120 EXP；社交影响力 +1。")
	else:
		_show_message("交易未完成", "信用点不足，或者该公开交流已经完成。没有扣除资源。")
	_update_hud()


func _gala_stage() -> void:
	if game_state.gala.performed:
		_show_message("星辉舞台", "今晚的演出已经完成。掌声被记录为公开声望，不会重复结算。")
		return
	_show_message("星辉舞台", "穿着白银星辉舞者服可进行一次礼仪演出。消耗 40 MP，获得 100 CR 与 2 点社交影响力；晚礼服状态下不会开始。")
	_add_dialogue_choice("登台演出", _gala_perform)
	_add_dialogue_choice("暂不上台", _close_modals)


func _gala_perform() -> void:
	if game_state.gala_perform():
		_show_message("凌霁 · 星辉演出", "动作利落而克制，舞步将战术节拍化为优雅的星轨。消耗 40 MP；获得 100 CR，社交影响力 +2。")
		_show_story_picture(load("res://assets/characters/lyra-gala-dancer-v1.png"))
	else:
		_show_message("无法开始演出", "需要先换上舞者服并保留至少 40 MP；已经完成的演出不能重复获取奖励。")
	_update_hud()


func _gala_broker() -> void:
	_show_message("顾迢 · 装备经纪人", "我只做明码交易。航运清单需要 1 点影响力与 70 CR，换取 80 EXP 和一条装备支线；星环偏导器需要 2 点影响力与 160 CR，永久增加 30 MP 上限。")
	if not game_state.gala.intel:
		_add_dialogue_choice("购买航运清单 · 70 CR", _gala_buy_intel)
	if not game_state.gala.resonator:
		_add_dialogue_choice("购买星环偏导器 · 160 CR", _gala_buy_resonator)
	_add_dialogue_choice("拒绝交易", _close_modals)


func _gala_buy_intel() -> void:
	if game_state.buy_gala_intel():
		_show_message("航运清单 · 已取得", "清单指向一批未登记的相位装备，后续可扩展为独立调查支线。获得 80 EXP。")
	else:
		_show_message("交易未完成", "需要至少 1 点社交影响力与 70 CR。没有扣除资源。")
	_update_hud()


func _gala_buy_resonator() -> void:
	if game_state.buy_gala_resonator():
		_show_message("星环偏导器 · 已装备", "装备将社交终端的闲置场能导入战术电容。MP 上限永久 +30，并立即补充 30 MP。")
	else:
		_show_message("交易未完成", "需要至少 2 点社交影响力与 160 CR。没有扣除资源。")
	_update_hud()


func _gala_lounge() -> void:
	_show_message("观星休息区", "支付 30 CR 可补充 25% 最大 HP 与 MP。满状态不会收费；也可以免费坐下观看星海，不恢复数值。")
	_add_dialogue_choice("购买休息服务 · 30 CR", _gala_rest)
	_add_dialogue_choice("免费放松，不恢复数值", _close_modals)


func _gala_rest() -> void:
	if game_state.gala_relax():
		_show_message("休息完成", "医疗织物与低频音乐缓解了疲劳。HP/MP 各恢复最大值的 25%。")
	else:
		_show_message("无需消费", "信用点不足或当前 HP/MP 均已满，没有扣除资源。")
	_update_hud()


func _enter_voyage() -> void:
	if not game_state.voyage.accepted:
		game_state.accept_voyage()
	_fly("starport")


func _he_cen() -> void:
	_show_message("贺岑 · 航务主管", "涅柔斯-4 的天气和生物信号都不稳定。我只能批准一件预装模块：绝缘组件能降低环境风险；备用电池则直接补充两枚标准电池。")
	if game_state.voyage.module_choice == "":
		_add_dialogue_choice("选择风暴绝缘组件", _choose_voyage_module.bind("insulation"))
		_add_dialogue_choice("选择备用 MP 电池 ×2", _choose_voyage_module.bind("battery"))
	else:
		_add_dialogue_choice("已领取：" + ("风暴绝缘组件" if game_state.voyage.module_choice == "insulation" else "备用电池"), _close_modals)


func _choose_voyage_module(choice: String) -> void:
	if game_state.choose_voyage_module(choice):
		_show_message("整备完成", "绝缘组件已写入外勤配置。" if choice == "insulation" else "两枚标准电池已加入道具背包。")
	_update_hud()


func _qi_wu() -> void:
	_show_message("祁雾 · 检疫工程师", "潮根会喷出高黏度纤维。抗黏附喷剂可在战斗中解除一次束缚，并提供三回合免疫。")
	if game_state.claim_anti_adhesion_spray():
		_add_dialogue_choice("收下喷剂", func() -> void: _show_message("祁雾", "已装入道具背包。它只对束缚有效，别浪费在普通擦伤上。"))
	else:
		_add_dialogue_choice("喷剂已领取", _close_modals)
	_update_hud()


func _voyage_enemy(enemy_id: String) -> void:
	if enemy_id in game_state.voyage.defeated:
		return
	var data: Dictionary = VOYAGE_ENCOUNTERS.config(enemy_id)
	_show_message(str(data.name), "%d HP · 攻击 %d—%d\n技能：%s\n掉落：%s" % [data.hp, data.damage.x, data.damage.y, data.skill, data.drop])
	_add_dialogue_choice("接战", _start_voyage_battle.bind(enemy_id))
	_add_dialogue_choice("观察后绕开", _close_modals)


func _start_voyage_battle(enemy_id: String) -> void:
	if mode == Mode.BATTLE or not VOYAGE_ENCOUNTERS.has(enemy_id) or enemy_id in game_state.voyage.defeated:
		return
	_close_modals()
	last_encounter = enemy_id
	mode = Mode.BATTLE
	player.call("set_controls_enabled", false)
	battle_screen.setup(game_state, enemy_id)
	battle_screen.set_environment(background.texture)


func _boarding() -> void:
	if location_id == "hangar":
		_show_message("游隼 · 航线确认", "已登记的外勤坐标可随时重返，调查进度会保留。选择本次目的地。")
		_add_dialogue_choice("ECHO-9 · 灰潮盆地", _fly.bind("landing"))
		if game_state.ruins.accepted:
			_add_dialogue_choice("阿斯佩拉 · 余烬村", _fly.bind("ruined_village"))
		if game_state.echo.reward_claimed:
			_add_dialogue_choice("潮汐盲区 · H1 星港候机环", _enter_voyage)
	elif location_id == "starport":
		_show_message("游隼 · 深空航线", "航线锁定涅柔斯-4。当地存在触手生物、认知污染与强风浪。完成整备后即可出发。")
		_add_dialogue_choice("起飞 · 前往潮根滩涂", _fly.bind("tentacle_field"))
		_add_dialogue_choice("暂不出发", _close_modals)
	elif location_id == "tentacle_field":
		_show_message("游隼 · 回收确认", "返回 H1 星港。战斗、材料与探索进度都会保留。")
		_add_dialogue_choice("返航", _fly.bind("starport"))
		_add_dialogue_choice("继续探索", _close_modals)
	else:
		var warning := "\n货船求救尚未处理，可返航后再次前往。" if location_id == "landing" and "wrecksite" in game_state.echo.visited and not game_state.echo.rescued else ""
		_show_message("游隼 · 返航确认", "调查、开箱、救援与修桥进度都会保留。返航不会自动补满 HP/MP。" + warning)
		_add_dialogue_choice("返回 H1 飞船舱", _fly.bind("hangar"))
	_add_dialogue_choice("再探索 / 整备一下", _close_modals)


func _build_flight() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 45
	add_child(layer)
	flight_panel = ColorRect.new()
	flight_panel.color = Color(0.025, 0.07, 0.13, 0.96)
	flight_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(flight_panel)
	var travel_art := TextureRect.new()
	travel_art.texture = load("res://assets/environments/echo-flight-v1.png")
	travel_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	travel_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	travel_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	travel_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flight_panel.add_child(travel_art)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.04, 0.08, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flight_panel.add_child(shade)
	flight_title = _label("", 32, Color("c4f7f2"))
	flight_title.position = Vector2(200, 235)
	flight_title.size = Vector2(880, 130)
	flight_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flight_panel.add_child(flight_title)
	flight_progress = ProgressBar.new()
	flight_progress.position = Vector2(260, 415)
	flight_progress.size = Vector2(760, 12)
	flight_progress.show_percentage = false
	flight_panel.add_child(flight_progress)
	var skip := Button.new()
	skip.text = "跳过航行演出  [ Enter / ESC ]"
	skip.position = Vector2(440, 500)
	skip.size = Vector2(400, 42)
	skip.pressed.connect(_finish_flight)
	flight_panel.add_child(skip)
	flight_panel.hide()


func _fly(destination: String) -> void:
	if flight_destination != "" or destination not in ["hangar", "landing", "ruined_village", "starport", "tentacle_field"] or location_id == destination:
		return
	var valid_pair := (location_id == "hangar" and destination in ["landing", "ruined_village", "starport"]) or (destination == "hangar" and location_id in ["landing", "ruined_village", "starport"]) or (location_id == "starport" and destination == "tentacle_field") or (location_id == "tentacle_field" and destination == "starport")
	if not valid_pair:
		return
	_close_modals()
	flight_destination = destination
	mode = Mode.MODAL
	player.call("set_controls_enabled", false)
	flight_panel.show()
	if destination == "landing":
		flight_title.text = "游隼 · 脱离停泊\n穿越电磁云层 → 灰潮盆地"
	elif destination == "ruined_village":
		flight_title.text = "游隼 · 远程跳跃\n废墟救难信标 → 阿斯佩拉"
	elif destination == "tentacle_field":
		flight_title.text = "游隼 · 深空跃迁\nH1 星港 → 涅柔斯-4 潮根滩涂"
	elif destination == "starport":
		flight_title.text = "游隼 · 回收航线\n涅柔斯-4 → H1 星港候机环"
	else:
		flight_title.text = "游隼 · 收拢舷梯\n返回 SITE OMEGA"
	flight_progress.value = 0
	flight_tween = create_tween()
	flight_tween.tween_property(flight_progress, "value", 100.0, 3.5)
	flight_tween.tween_callback(_finish_flight)


func _finish_flight() -> void:
	if flight_destination == "":
		return
	var destination := flight_destination
	flight_destination = ""
	if is_instance_valid(flight_tween):
		flight_tween.kill()
	flight_panel.hide()
	if destination == "landing":
		game_state.echo.patrol_down = false
	_set_location(destination)
	if destination == "ruined_village":
		_show_message("余烬村 / 遮天", "葬潮号已经离开低轨，但它的阴影仍覆在阿斯佩拉的残骸上。沈砚：“不要锁定它。先带活着的人离开，再找它留下的弱点。”")
		_show_story_picture(ECLIPSE_CARRIER_CG)
		_add_dialogue_choice("降落余烬村 · 开始救援", _close_modals)


func _antenna() -> void:
	_show_message("天线控制箱", "检修铭牌：三段波形应依次为「短—长—短」。\n只下载本地记录不会引来敌人。启动灯标可显示更多道路，但会吸引一台可绕开的巡逻机。")
	_add_dialogue_choice("只下载本地定位记录", _download_antenna)
	if not game_state.echo.beacon_on:
		_add_dialogue_choice("校准并启动灯标（会暴露位置）", _start_puzzle.bind("antenna"))
	_add_dialogue_choice("暂时离开", _close_modals)


func _download_antenna() -> void:
	game_state.collect_echo_clue("highland")
	_show_message("高地定位记录", "收到旧观测站的定向脉冲。记录末尾仍使用 SITE OMEGA 的识别格式。\n已记录一份独立线索；重复读取不会重复计数。")
	_update_hud()


func _manifest() -> void:
	game_state.collect_echo_clue("wrecksite")
	_show_message("货舱运输单", "收货地：ECHO-9 观测站。货物：神经签名校验器。\n运输人员胸牌与单据可相互核验，旁边的生存舱仍有求救敲击声。\n定位线索与运输单已归档，不占背包。")
	_update_hud()


func _rescue() -> void:
	if game_state.echo.rescued:
		return
	_show_message("生存舱 · 求救声", "舱内的维修员仍然清醒。舱外手册：先「泄压」，再「断电」，最后「开锁」。\n手动操作不消耗 MP 或道具；也可以先调查运输单，核验他的身份。")
	_add_dialogue_choice("操作手动救援锁", _start_puzzle.bind("rescue"))
	_add_dialogue_choice("先问身份", func() -> void:
		_show_message("舱内的维修员", "“我是观测站的外勤维修员，胸牌编号就在运输单上。救我出来，我可以告诉你维护入口。”\n" + ("胸牌与运输单一致。" if "wrecksite" in game_state.echo.clues else "尚未查看运输单，你可以先去货舱核验。"))
		_add_dialogue_choice("返回生存舱操作", _rescue))
	_add_dialogue_choice("稍后回来", _close_modals)


func _survivor() -> void:
	_show_message("获救维修员", "“观测站西侧外墙有三个检修标记：先旁路供电，再验压，最后开舱。不用跟正门的守卫硬碰硬。”\n他正在游隼旁等待撤离，救援奖励已领取，不会重复发放。")


func _bridge() -> void:
	game_state.collect_echo_clue("ravine")
	_show_message("断桥控制箱", "桥梁维护记录带有观测站的地形坐标，已加入定位线索。\n检修流程：「接地—供电—搭桥」。修好后可从北侧高架直接回着陆点。未修好时可从裂隙南端绕行。")
	if not game_state.echo.bridge_fixed:
		_add_dialogue_choice("手动修复桥梁", _start_puzzle.bind("bridge"))
	_add_dialogue_choice("继续探索", _close_modals)
	_update_hud()


func _shortcut() -> void:
	if game_state.echo.bridge_fixed:
		_set_location("landing")
	else:
		_show_message("高架捷径 · 安全锁定", "先修复东侧控制箱，桥梁才会连通。南侧雪地绕行道路始终开放。")


func _cache() -> void:
	if game_state.echo.cache_claimed:
		_show_message("测绘箱已开启", "测绘插件已并入导航，不占用战斗模块槽，不增加战斗倍率。")
		return
	_show_message("封存测绘箱", "锁上的图形表示：「山脊—河谷—营地」。这不是主任务必需物品。\n箱内测绘插件可以显示区域道路与捷径提示，不叠加战斗属性。")
	_add_dialogue_choice("按图形解锁", _start_puzzle.bind("cache"))
	_add_dialogue_choice("暂时离开", _close_modals)


func _ruins_crater() -> void:
	game_state.collect_ruins_clue("crater")
	_show_message("航母钻击坑", "地表被精确剥开，却没有常规轰炸的放射性残留。钻头以与星核同相的脉冲建立抽取锁，并在末端锁定本地基频。\n凌霁记下：反制序列以反相开始，以锁频结束。")
	if game_state.mi_po.trust >= 30 and game_state.ruins.secret_recovered and not game_state.mi_po.quest_complete:
		_add_dialogue_choice("调整钻击坑共振节点", _mi_po_resonance_node.bind("crater", "钻击坑"))
	_update_hud()


func _ruins_shelter() -> void:
	if game_state.ruins.shelter_secured:
		_show_message("温室避难所", "岚禾与七名幸存者已转移到稳定供氧区。他们正在整理星历库的校验短句，等待凌霁带回两份可核验记录。")
		return
	_show_message("温室避难所 · 八个生命信号", "过滤器停机，但现场旁路仍可使用。凌霁可以先稳定供氧，再调查废墟；救援不消耗唯一任务道具。")
	_add_dialogue_choice("接通旁路，稳定幸存者避难所", _secure_ruins_shelter)
	_add_dialogue_choice("稍后回来", _close_modals)


func _secure_ruins_shelter() -> void:
	if game_state.secure_ruins_shelter():
		_show_message("避难所已稳定", "岚禾与七名幸存者主动转移伤员、清点物资。岚禾：“归潮协议属于阿斯佩拉。先证明你理解它的风险，我们再共同授权。”")
		_update_hud()


func _ruins_memorial() -> void:
	game_state.collect_ruins_clue("memorial")
	_show_message("村口纪念塔", "塔下的紧急记录仍在循环：余烬村将防护阵列先反相，再延迟两拍，短暂打断航母锁定，为撤离争取了七分钟。\n记录把这种防卫算法称为「归潮协议」。")
	if game_state.mi_po.met and game_state.mi_po.nameplates_taken and not game_state.mi_po.nameplates_placed:
		_add_dialogue_choice("将七枚遇难者姓名片嵌入纪念墙", _place_mi_po_nameplates)
	elif game_state.mi_po.nameplates_placed:
		_add_dialogue_choice("重读七人的姓名与生前职责", _review_mi_po_nameplates)
	_update_hud()


func _ruins_observatory() -> void:
	game_state.collect_ruins_clue("observatory")
	_show_message("倒塌的观测台", "一幅最后的星图指向蓝星：海盗已抽取超过半数已知星核，下一个目标就是地球。\n观测员留下的校验表明：反相脉冲必须先等待两拍，再锁定本地基频，才能让抽取锁误判。")
	if game_state.mi_po.trust >= 30 and game_state.ruins.secret_recovered and not game_state.mi_po.quest_complete:
		_add_dialogue_choice("调整观测台共振节点", _mi_po_resonance_node.bind("observatory", "观测台"))
	_update_hud()


func _mi_po() -> void:
	if not game_state.ruins.shelter_secured:
		_show_message("独立共振舱", "调弦系统拒绝在避难所生命支持稳定前开启。")
		return
	if not game_state.mi_po.met:
		_show_dialogue("余烬村 / 第九个信号", "弥珀", "“停在线外，蓝星执行者。你的脉搏是真的，你携带的坐标却有一半在说谎。”\n凌霁：“所以别相信我的制服。告诉我怎么证明。”\n弥珀：“三次校验。时间、生命，以及你怎样对待不能再回答的人。”")
		_add_dialogue_choice("接受校验 · 收下七枚姓名片", _meet_mi_po)
		_add_dialogue_choice("暂时离开", _close_modals)
		return
	if game_state.mi_po.nameplates_placed and not game_state.mi_po.memorial_returned:
		if game_state.complete_mi_po_check("memorial"):
			_save_mi_po_progress()
			_show_dialogue("为活者调弦 / NAME RETURN", "弥珀", "“你没有问他们能换多少装备。凌霁，这是我第一次直接叫你的名字。”\n三项校验完成后，弥珀将共享隐藏相位节点。")
			_add_dialogue_choice("继续", _close_modals)
			_update_hud()
			return
	if game_state.mi_po.trust < 30:
		_show_dialogue("为活者调弦 / VALIDATION", "弥珀", "完成真实性校验：档案时钟 %s，生命脉搏 %s，姓名归还 %s。" % ["已完成" if game_state.mi_po.clock_restored else "未完成", "已完成" if game_state.mi_po.pulse_verified else "未完成", "已完成" if game_state.mi_po.memorial_returned else ("待复命" if game_state.mi_po.nameplates_placed else "待送往纪念墙")])
		return
	if not game_state.ruins.secret_recovered:
		_show_dialogue("为活者调弦 / WAIT", "弥珀", "先完成「归潮协议」的相位逆演。那之后，我会将三处生活档案节点交给你校正。")
		return
	if game_state.mi_po.quest_complete:
		var closure: String = "我们将共同管理这些记忆。" if game_state.mi_po.trust == 80 else "技术副本已完成封存，我会继续履行职业监督。"
		_show_dialogue("为活者调弦 / ARCHIVED", "弥珀", closure)
		return
	if not game_state.mi_po_resonance_ready():
		_show_dialogue("为活者调弦 / RESONANCE", "弥珀", "三处生活档案节点必须同时校正：钻击坑、倒塌观测台、地下档案库。\n我能解释频谱，但不会替你做选择。")
		return
	_show_dialogue("为活者调弦 / CUSTODY", "弥珀", "生活档案已解锁。首先决定它的保管方式。")
	_add_dialogue_choice("阿斯佩拉幸存者与蓝星共同保管", _choose_mi_po_custody.bind("shared"))
	_add_dialogue_choice("SITE OMEGA 单方封存完整副本", _choose_mi_po_custody.bind("omega"))


func _meet_mi_po() -> void:
	if game_state.meet_mi_po():
		_save_mi_po_progress()
		_show_dialogue("为活者调弦 / START", "弥珀", "档案时钟与生命频谱台已开放。七枚遇难者姓名片已交给你；请亲自把它们送回地表纪念墙。")
		_add_dialogue_choice("开始校验", _close_modals)
		_update_hud()


func _mi_po_clock() -> void:
	if game_state.mi_po.clock_restored:
		_show_message("档案时钟", "已以天体事件恢复真实时序。")
		return
	if not game_state.mi_po.met:
		return
	_start_puzzle("mi_po_clock")


func _mi_po_pulse() -> void:
	if game_state.mi_po.pulse_verified:
		_show_message("生命频谱台", "信号 B-17 已确认为真实生命脉搏。")
		return
	if not game_state.mi_po.met:
		return
	_show_message("生命频谱台", "三组信号同时出现。真实生命会有不完全周期、呼吸漂移和现场延迟。")
	_add_dialogue_choice("A-04 · 完美周期 · 零延迟", _choose_mi_po_pulse.bind(false))
	_add_dialogue_choice("B-17 · 不规则周期 · 呼吸漂移 · 23ms延迟", _choose_mi_po_pulse.bind(true))
	_add_dialogue_choice("C-31 · 完美周期 · 固定漂移", _choose_mi_po_pulse.bind(false))


func _choose_mi_po_pulse(correct: bool) -> void:
	if correct and game_state.complete_mi_po_check("pulse"):
		_save_mi_po_progress()
		_show_message("生命脉搏 · 校验通过", "弥珀：“镜像完美得像一段录音。真正活着的东西会犹豫。”")
	else:
		_show_message("生命脉搏 · 矛盾", "该信号的周期和漂移过于完美，与现场传输延迟矛盾。三组信号保留，请重新判断。")
		_add_dialogue_choice("重新检查", _mi_po_pulse)
	_update_hud()


func _place_mi_po_nameplates() -> void:
	if game_state.place_mi_po_nameplates():
		_save_mi_po_progress()
		_show_message("姓名归还", "七枚姓名片依次归位：教师、农学员、医生、航路员、维修师、谱曲者与档案管理员。\n返回地下共振舱，向弥珀复命。")
		_update_hud()


func _review_mi_po_nameplates() -> void:
	_show_message("纪念墙 · 七个姓名", "他们是教师、农学员、医生、航路员、维修师、谱曲者与档案管理员。姓名可重读，不会重复结算。")


func _mi_po_resonance_node(node_id: String, node_title: String) -> void:
	if game_state.mi_po.trust < 30 or not game_state.ruins.secret_recovered or game_state.mi_po.quest_complete:
		return
	_show_message(node_title + " · 共振节点", "选择该节点的相位。三处都确认后才会校验组合；错误只复位本轮，不损失资源。")
	_add_dialogue_choice("正相", _set_mi_po_resonance.bind(node_id, "positive"))
	_add_dialogue_choice("反相", _set_mi_po_resonance.bind(node_id, "inverse"))
	_add_dialogue_choice("静默", _set_mi_po_resonance.bind(node_id, "silent"))


func _set_mi_po_resonance(node_id: String, phase_value: String) -> void:
	if not game_state.set_resonance_node(node_id, phase_value):
		return
	if game_state.mi_po.resonance_nodes.size() == 3 and not game_state.mi_po_resonance_ready():
		game_state.reset_mi_po_resonance()
		_save_mi_po_progress()
		_show_message("三点共振 · 安全复位", "三处频谱未能形成闭环。弥珀保留了生活档案，本轮节点已复位。\n提示：钻击坑需要抵消抽取，观测台需要避免回声，档案库需要恢复输出。")
	else:
		_save_mi_po_progress()
		_show_message("共振节点 · 已记录", "当前已确认 %d/3。%s" % [game_state.mi_po.resonance_nodes.size(), "三点闭环已成立，返回弥珀处决定档案去向。" if game_state.mi_po_resonance_ready() else "可离开后前往下一处节点。"])
	_update_hud()


func _choose_mi_po_custody(choice: String) -> void:
	mi_po_custody_choice = choice
	_show_dialogue("为活者调弦 / PRIORITY", "弥珀", "保管方式已记录。现在选择首班运输的优先顺序。")
	_add_dialogue_choice("优先撤离生活档案和幸存者", _finish_mi_po_quest.bind("civilian"))
	_add_dialogue_choice("优先回收稀有军用调谐模块", _finish_mi_po_quest.bind("military"))


func _finish_mi_po_quest(priority: String) -> void:
	if not game_state.resolve_mi_po_archive(mi_po_custody_choice, priority) or not game_state.complete_mi_po_quest():
		return
	_save_mi_po_progress()
	var result: String = "弥珀将共振核心接入反相支援频道。" if game_state.mi_po.trust == 80 else ("相位电容已回收；今后每场战斗开场补充 30 MP。" if game_state.mi_po.module_claimed else "档案已按选定方式封存。")
	_show_dialogue("为活者调弦 / COMPLETE", "弥珀", "“我曾以为，只要没有离开，阿斯佩拉就不算结束。”\n凌霁：“离开不代表把它留下。”\n弥珀：“那就让我看看，记忆如何和活着的人一起航行。”\n\n获得 160 CR / 220 EXP。" + result)
	_add_dialogue_choice("结束交谈", _close_modals)
	_update_hud()


func _save_mi_po_progress() -> void:
	game_state.saved_location = location_id
	game_state.save_progress()


func _phase_core() -> void:
	if game_state.ruins.secret_recovered:
		_show_message("星核相位库", "「归潮协议」已写入隔离芯片：反相、延迟两拍、锁定本地基频。\n它能在蓝星外围制造一次断锁窗口，但不能自动击毁航母。")
		return
	if not game_state.ruins.shelter_secured:
		_show_message("星核相位库", "协议需要阿斯佩拉幸存者的最后校验短句。先返回温室避难所，稳定生命支持并取得共同授权。")
		return
	if game_state.ruins.clues.size() < 2:
		_show_message("星核相位库", "终端需要两份独立记录交叉核验。返回余烬村，从钻击坑、纪念塔与观测台中任意调查两处。")
		return
	_show_message("星核相位库", "两份记录已可重建「归潮协议」。顺序错误只会触发隔离复位，不会消耗道具。" + ("\n三处记录已齐全；终端会在错误时标出当前步骤。" if game_state.ruins.clues.size() == 3 else ""))
	_add_dialogue_choice("开始重建反制序列", _start_puzzle.bind("phase_lock"))
	_add_dialogue_choice("返回村庄复核记录", _travel.bind("ruined_village"))


func _start_puzzle(kind: String) -> void:
	current_puzzle = kind
	puzzle_progress = 0
	_puzzle_dialogue()


func _puzzle_dialogue(feedback: String = "") -> void:
	var instructions := {"antenna": "短—长—短", "rescue": "泄压—断电—开锁", "bridge": "接地—供电—搭桥", "cache": "山脊—河谷—营地", "maintenance": "旁路—验压—开舱", "phase_lock": "钻击坑 → 纪念塔 → 观测台", "mi_po_clock": "天体事件比终端时戳更可信"}
	var options := {"antenna": ["长", "短"], "rescue": ["开锁", "泄压", "断电"], "bridge": ["搭桥", "接地", "供电"], "cache": ["营地", "山脊", "河谷"], "maintenance": ["验压", "开舱", "旁路"], "phase_lock": ["锁频", "反相", "延迟两拍"], "mi_po_clock": ["剥离伪时戳", "天文锚定", "断电对时"]}
	_show_message("手动操作 · %d/3" % puzzle_progress, "%s\n检修线索：%s。顺序错误只复位，不扣资源。" % [feedback, instructions[current_puzzle]])
	for value: String in options[current_puzzle]:
		_add_dialogue_choice(value, _puzzle_choose.bind(value))
	_add_dialogue_choice("取消操作", _close_modals)


func _puzzle_choose(value: String) -> void:
	var sequences := {"antenna": ["短", "长", "短"], "rescue": ["泄压", "断电", "开锁"], "bridge": ["接地", "供电", "搭桥"], "cache": ["山脊", "河谷", "营地"], "maintenance": ["旁路", "验压", "开舱"], "phase_lock": ["反相", "延迟两拍", "锁频"], "mi_po_clock": ["天文锚定", "断电对时", "剥离伪时戳"]}
	if current_puzzle not in sequences or puzzle_progress >= 3:
		return
	if value != sequences[current_puzzle][puzzle_progress]:
		var expected: String = sequences[current_puzzle][puzzle_progress]
		puzzle_progress = 0
		var hint: String = " 完整校验记录标出：当前应为「%s」。" % expected if current_puzzle == "phase_lock" and game_state.ruins.clues.size() == 3 else ""
		_puzzle_dialogue("顺序不符，装置安全复位。" + hint)
		return
	puzzle_progress += 1
	if puzzle_progress < 3:
		_puzzle_dialogue("接口响应正常。")
		return
	var feedback := ""
	match current_puzzle:
		"antenna":
			game_state.collect_echo_clue("highland")
			game_state.echo.beacon_on = true
			feedback = "灯标上线。按 M 可查看完整道路提示；一台巡逻机已被信号吸引，可绕开它。"
		"rescue":
			if not game_state.echo.rescued:
				game_state.echo.rescued = true
				game_state.grant_reward(60, 80)
			feedback = "维修员已沿安全路线前往着陆点。获得 60 CR / 80 EXP。\n他告诉你：观测站西侧有维护口，按旁路—验压—开舱可进入。"
		"bridge":
			if not game_state.echo.bridge_fixed:
				game_state.echo.bridge_fixed = true
				game_state.grant_reward(0, 60)
			feedback = "桥面展开，碰撞阻挡已解除。获得 60 EXP；北侧高架捷径可以返回着陆点。"
		"cache":
			game_state.echo.cache_claimed = true
			game_state.echo.survey_module = true
			feedback = "获得测绘插件。按 M 查看区域道路和捷径；不占战斗模块槽。"
		"maintenance":
			game_state.echo.entry = "maintenance"
			feedback = "维护通道已开启，绕过正门守卫。现在可以从维护口进入档案室，核验定位线索。"
		"phase_lock":
			game_state.recover_phase_secret()
			feedback = "「归潮协议」已导入隔离芯片。它能在海盗航母对蓝星星核建立抽取锁时，制造一次断锁窗口。\n这是拦截条件，不是最终航母战的自动胜利。"
		"mi_po_clock":
			game_state.complete_mi_po_check("clock")
			_save_mi_po_progress()
			feedback = "档案时钟已按天文锚定、断电对时、剥离伪时戳的顺序恢复。系统时间不再覆盖真实事件。"
	current_puzzle = ""
	_refresh_world()
	_show_message("操作完成", feedback)
	if game_state.echo.entry == "maintenance" and location_id == "station":
		_add_dialogue_choice("沿维护通道进入档案室", _enter_archive)
	_update_hud()


func _gate() -> void:
	_show_message("观测站正门", "守卫拒绝未知访客。你可以正面交战，也能沿西侧寻找维护标记，或到东侧终端协商身份。\n这场战斗不是必需；守卫有 220 HP，可撤离。")
	_add_dialogue_choice("与正门守卫交战", _start_echo_battle.bind("echo_guard"))
	_add_dialogue_choice("后退，另找入口", _close_modals)


func _maintenance() -> void:
	if game_state.echo.entry != "":
		_enter_archive()
		return
	_show_message("西侧维护入口", "外墙刻着三枚旧检修标记：电源旁路、压力表、舱门。它们组成「旁路—验压—开舱」。\n" + ("获救维修员提供的口令与标记吻合。" if game_state.echo.rescued else "即使没有维修员帮助，也能通过观察发现这里。"))
	_add_dialogue_choice("操作维护门锁", _start_puzzle.bind("maintenance"))
	_add_dialogue_choice("离开", _close_modals)


func _permit() -> void:
	if game_state.echo.clues.size() < 2 or "wrecksite" not in game_state.echo.clues:
		_show_message("身份协商终端", "需要两份独立定位记录，以及坠毁货船的运输单，才能说明认证冲突。\n这不是唯一入口，你也可以寻找西侧维护标记。")
		return
	_show_message("身份协商终端", "运输单证明这里仍是 SITE OMEGA 的接收站；两份定位记录却与当前访客名单冲突。你可以据此申请隔离调查。")
	_add_dialogue_choice("指出认证矛盾，申请调查许可", _obtain_permit)
	_add_dialogue_choice("取消", _close_modals)


func _obtain_permit() -> void:
	if game_state.echo.clues.size() >= 2 and "wrecksite" in game_state.echo.clues:
		game_state.echo.entry = "permit"
		_show_message("调查许可已签发", "无需交战。现在可从正门进入档案室，完成身份核验。")
		_add_dialogue_choice("进入档案室", _enter_archive)
		_update_hud()


func _enter_archive() -> void:
	if game_state.echo.entry == "":
		_show_message("观测站门锁", "尚未取得入口权限。东侧终端可以协商，西侧外墙可寻找检修标记。正面交战不是必需的。")
		return
	_set_location("archive")


func _core() -> void:
	if game_state.echo.entry == "":
		_show_message("观测站记录控制台", "尚未取得入口权限。正门交战、西侧检修口和东侧身份协商终端都可尝试。")
		return
	if game_state.echo.clues.size() < 2:
		_show_message("记录核验未完成", "需要两份来自不同地点的定位记录。高地、货船、栈道可任意选择，不需要按顺序访问。")
		return
	if game_state.echo.outcome != "":
		_show_message("记录已隔离备份", "LYRA-7 的返航请求已获批准。时间：三年前；发送地点：SITE OMEGA。\n信标处置已保存，可返航汇报或继续探索。")
		return
	_show_message("三年前的返航请求", "记录：‘LYRA-7 的返航请求已获批准。’时间戳：三年前；发送地点：SITE OMEGA。\n这还不能证明凌霁来过这里。你已复制静态档案，接下来决定如何处理信标。")
	_add_dialogue_choice("保留信标，继续追踪（下一步确认）", _confirm_outcome.bind("keep"))
	_add_dialogue_choice("关闭信标，解除区域警戒（下一步确认）", _confirm_outcome.bind("shutdown"))
	_add_dialogue_choice("暂不决定", _close_modals)


func _confirm_outcome(outcome: String) -> void:
	_show_message("不可逆处置 · 请确认", "保留：继续追踪后续回应，但巡逻机仍保持活动。基础奖励 300 CR / 300 EXP。" if outcome == "keep" else "关闭：保留已复制档案，但不能实时追踪；附近受控巡逻机停机。基础奖励同样是 300 CR / 300 EXP。")
	_add_dialogue_choice("确认此处置", _resolve_outcome.bind(outcome))
	_add_dialogue_choice("返回，不做改变", _core)


func _resolve_outcome(outcome: String) -> void:
	if game_state.resolve_echo(outcome):
		_refresh_world()
		_core()
		_update_hud()


func _patrol_dialogue() -> void:
	_show_message("巡逻机 · 可绕行", "巡逻机正在灯标附近搜索。它不会堵死雪地道路。接战前可后退；击败获得 30 CR / 60 EXP，返基地后再次出航会刷新普通巡逻机。")
	_add_dialogue_choice("接战 · 150 HP", _start_echo_battle.bind("echo_patrol"))
	_add_dialogue_choice("后退，绕路", _close_modals)


func _start_echo_battle(encounter: String) -> void:
	if mode == Mode.BATTLE or encounter not in ["echo_patrol", "echo_guard"] or game_state.echo.outcome == "shutdown":
		return
	if (encounter == "echo_guard" and game_state.echo.guard_down) or (encounter == "echo_patrol" and game_state.echo.patrol_down):
		return
	_close_modals()
	last_encounter = encounter
	mode = Mode.BATTLE
	player.call("set_controls_enabled", false)
	battle_screen.setup(game_state, encounter)
	battle_screen.set_environment(background.texture)


func _on_battle_won() -> void:
	if mode != Mode.BATTLE:
		return
	if last_encounter == "echo_guard" and not game_state.echo.guard_down:
		game_state.echo.guard_down = true
		game_state.echo.entry = "combat"
	elif last_encounter == "echo_patrol" and not game_state.echo.patrol_down:
		game_state.echo.patrol_down = true
		game_state.grant_reward(30, 60)
	elif VOYAGE_ENCOUNTERS.has(last_encounter):
		var data: Dictionary = VOYAGE_ENCOUNTERS.config(last_encounter)
		game_state.record_voyage_victory(last_encounter, data.credits, data.exp, data.drop)
	_refresh_world()
	_close_modals()
	_update_hud()


func _on_battle_retreated() -> void:
	_close_modals()
	_update_hud()


func _on_player_defeated() -> void:
	game_state.recover_after_defeat()
	if last_encounter.begins_with("voyage_"):
		_set_location("starport")
		_show_message("H1 星港 · 紧急回收", "祁雾完成隔离清洗，HP 恢复至 35%。已取得的材料和探索成果保留。")
	else:
		_set_location("landing")
		_show_message("游隼 · 紧急回收", "岑遥将你送回着陆点，HP 恢复至 35%。已取得的线索和探索成果保留。可以绕开战斗，或登舰返航。")
