extends "res://scripts/exploration.gd"

const FINALE_MAP := preload("res://assets/environments/yue-final-map-v1.png")
const YUE_ART := preload("res://assets/enemies/yue-chenge-normal-v1.png")
const CEREMONY_CG := preload("res://assets/story/lyra-commander-ceremony-v1.png")

var finale_points: Dictionary = {}
var map_objects: Node2D
var camera: Camera2D
var ending_active: bool = false


func _ready() -> void:
	if not game_state.pirate_arc.wen_defeated:
		game_state.saved_location = "command"
		get_tree().call_deferred("change_scene_to_file", "res://scenes/exploration.tscn")
		return
	if not game_state.pirate_arc.yue_defeated:
		game_state.begin_finale()
	_build_background()
	_build_world()
	_build_hud()
	_build_battle()
	_update_hud()
	if game_state.pirate_arc.true_end_seen:
		_show_true_end()


func _build_background() -> void:
	background = TextureRect.new()
	background.texture = FINALE_MAP
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.size = Vector2(1536, 1024)
	background.z_index = -20
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	world_shade = ColorRect.new()
	world_shade.size = Vector2(1536, 1024)
	world_shade.color = Color(0.02, 0.025, 0.035, 0.08)
	world_shade.z_index = -19
	world_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(world_shade)


func _build_world() -> void:
	y_sort_enabled = true
	map_objects = Node2D.new()
	map_objects.y_sort_enabled = true
	add_child(map_objects)
	player = CharacterBody2D.new()
	player.name = "LYRA7"
	player.set_script(PLAYER_SCRIPT)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 9.0
	collision.shape = shape
	player.add_child(collision)
	player.position = Vector2(470, 835)
	player.movement_bounds = Rect2(90, 100, 1350, 820)
	add_child(player)
	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1536
	camera.limit_bottom = 1024
	player.add_child(camera)
	camera.make_current()

	_make_finale_point("cooling", "冷却廊桥 · 相位阀", Vector2(255, 715), _calibrate.bind(0))
	_make_finale_point("ring", "惯性校准环 · 三轨同步", Vector2(760, 505), _calibrate.bind(1))
	_make_finale_point("anchor", "星核抽取锚 · 真实签名", Vector2(1110, 270), _calibrate.bind(2))
	_make_finale_point("yue", "岳沉戈 · 断舰统领", Vector2(1225, 325), _start_yue_battle, YUE_ART)


func _make_finale_point(id: String, title: String, at: Vector2, callback: Callable, texture: Texture2D = null) -> void:
	var node := _marker(title, at, Color("e6a84c") if id == "yue" else Color("64eee5"))
	if texture != null:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.scale = Vector2.ONE * (112.0 / texture.get_height())
		sprite.position.y = -54
		node.add_child(sprite)
	var badge := _label("!", 30, Color("ffd35a"))
	badge.name = "QuestBadge"
	badge.position = Vector2(-14, -150 if texture != null else -106)
	badge.size = Vector2(28, 36)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_color_override("font_outline_color", Color("402c09"))
	badge.add_theme_constant_override("outline_size", 6)
	node.add_child(badge)
	map_objects.add_child(node)
	finale_points[id] = {"node": node, "callback": callback, "title": title}


func _process(_delta: float) -> void:
	if not is_instance_valid(player) or mode != Mode.EXPLORE:
		return
	var target := _nearest_finale_target()
	interaction_tip.text = "[ E ] " + str(finale_points[target].title) if target != "" else "沿青蓝节点前进 · 完成三段主炮相位校准"
	for id: String in finale_points:
		var point: Node2D = finale_points[id].node
		var badge := point.get_node("QuestBadge") as Label
		badge.visible = id == _objective_id()


func _unhandled_input(event: InputEvent) -> void:
	if mode == Mode.BATTLE:
		return
	if event.is_action_pressed("ui_cancel"):
		if ending_active:
			return
		if mode == Mode.MODAL:
			_close_modals()
		else:
			_return_base()
		return
	if mode == Mode.EXPLORE and event.is_action_pressed("interact"):
		var target := _nearest_finale_target()
		if target != "":
			finale_points[target].callback.call()


func _nearest_finale_target() -> String:
	var nearest := ""
	var distance := 120.0
	for id: String in finale_points:
		var point: Node2D = finale_points[id].node
		if not point.visible:
			continue
		var next_distance := player.position.distance_to(point.position)
		if next_distance < distance:
			distance = next_distance
			nearest = id
	return nearest


func _objective_id() -> String:
	var step := int(game_state.pirate_arc.finale_calibration)
	return ["cooling", "ring", "anchor", "yue"][clampi(step, 0, 3)]


func _calibrate(step: int) -> void:
	if not game_state.calibrate_finale_node(step):
		_show_dialogue("断舰庭 / SEQUENCE ERROR", "澄明手环", "相位顺序不成立。先完成当前带有感叹号的青蓝节点。")
		_add_dialogue_choice("返回地图", _close_modals)
		return
	var messages: Array[String] = [
		"冷却阀已反向锁定。主炮下一次蓄能将留下可验证的热差。",
		"拳甲、炮架与抽取锚的三条惯性轨道完成反相同步。完美防御可以积累反击窗口。",
		"真实指令校验签名写入抽取锚。岳沉戈无法再调用伪造增援，断舰庭开放。",
	]
	_show_dialogue("归潮 / CALIBRATION %d/3" % (step + 1), "凌霁", messages[step])
	_add_dialogue_choice("继续深入", _close_modals)
	_update_hud()


func _start_yue_battle() -> void:
	if int(game_state.pirate_arc.finale_calibration) < 3:
		_show_dialogue("断舰庭 / LOCKED", "澄明手环", "三处主炮相位尚未全部校准。")
		_add_dialogue_choice("返回地图", _close_modals)
		return
	_close_modals()
	mode = Mode.BATTLE
	player.call("set_controls_enabled", false)
	battle_screen.setup(game_state, "yue_chenge")


func _on_battle_won() -> void:
	if battle_screen.encounter_id != "yue_chenge":
		return
	mode = Mode.MODAL
	player.call("set_controls_enabled", false)
	_show_true_end()


func _on_battle_retreated() -> void:
	mode = Mode.EXPLORE
	player.call("set_controls_enabled", true)
	_update_hud()


func _on_player_defeated() -> void:
	game_state.recover_after_defeat()
	mode = Mode.MODAL
	_show_dialogue("断舰庭 / CHECKPOINT", "澄明手环", "断舰式冲击令外骨骼失去响应。紧急回收把凌霁送回校准环；三处相位记录仍然保留，不必重打闻缄。")
	_add_dialogue_choice("重新整备", _close_modals)
	_update_hud()


func _show_true_end() -> void:
	ending_active = true
	var header := "TRUE END / 归潮新生"
	var speaker := "凌霁 · 首位女性统帅"
	var line := "岳沉戈的断舰核心崩解，蓝星星核回归稳定轨道。葬潮号解除主炮与非法中继后改名为归潮号，进入多文明联合监管。\n\n沈砚：“你要守住的，是每个人判断真相和选择道路的权利。”\n凌霁：“归潮号会去所有仍在等待回应的地方。”"
	if int(game_state.mi_po.trust) >= 80:
		line += "\n\n授衔广场前排，岚禾与弥珀代表阿斯佩拉幸存者坐入监督席。弥珀保有星核技术主密钥，与蓝星共同管理归潮号。"
	elif int(game_state.mi_po.trust) >= 30:
		line += "\n\n弥珀以阿斯佩拉档案见证员的身份出席授衔，对归潮号的后续使用保留独立监督权。"
	_show_dialogue(header, speaker, line)
	_add_dialogue_choice("完成授衔 · 返回指挥中心", _return_base)
	_show_wen_bad_end_picture(CEREMONY_CG, header, speaker, line, "完成授衔 · 返回指挥中心", _return_base)


func _return_base() -> void:
	ending_active = false
	game_state.saved_location = "command"
	game_state.save_progress()
	get_tree().change_scene_to_file("res://scenes/exploration.tscn")


func _update_hud() -> void:
	if location_label == null:
		return
	location_label.text = "当前位置 / CURRENT LOCATION\n葬潮号 · 主炮脊柱"
	mission_title.text = "归潮 / 断舰之庭"
	var step := int(game_state.pirate_arc.finale_calibration)
	mission_text.text = "完成主炮相位校准 %d/3。" % step if step < 3 else ("岳沉戈已战败，授衔记录完成。" if game_state.pirate_arc.yue_defeated else "进入断舰庭，击败岳沉戈双形态。")
	interaction_tip.text = "沿青蓝节点前进"
	hud_portrait.texture = CHARACTER_ART.portrait(game_state)
	player_status.text = "凌霁 · LYRA-7    CR %d\nHP %d/%d    MP %d/%d\n终战校准 %d/3" % [game_state.credits, game_state.health, game_state.max_health, game_state.energy, game_state.max_energy, step]
	game_state.saved_location = "finale"
	game_state.save_progress()
