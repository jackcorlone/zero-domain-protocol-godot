extends Node2D

enum Mode { EXPLORE, MODAL }

const MAP_BACKGROUND_PATH := "res://assets/environments/mech-yard-map-2d-v2.png"
const REDLINE_MAP_PATH := "res://assets/mechs/redline-seraph-map-sheet-v2.png"
const WHITE_MAP_PATH := "res://assets/mechs/white-aegis-map-sheet-v2.png"
const IRON_MAP_PATH := "res://assets/mechs/iron-bastion-map-sheet-v2.png"
const BACKGROUND := preload("res://assets/environments/mech-bay-2d-v1.png")
const PLAYER_SCRIPT := preload("res://scripts/player.gd")
const WHITE_AEGIS := preload("res://assets/mechs/white-aegis-icon-v1.png")
const IRON_BASTION := preload("res://assets/mechs/iron-bastion-icon-v1.png")
const REDLINE_SERAPH := preload("res://assets/mechs/redline-seraph-icon-v1.png")

const EXHIBITS := {
	"white_aegis": {
		"name": "白曜神盾 / WHITE AEGIS", "role": "友方支援机 · 高机动防卫型",
		"stats": "耐久 B    机动 A    火力 B\n特性：相位护盾 · 短距推进 · 精密格挡",
		"description": "白曜神盾正在守卫外围通路。\n它可为赤线炽天提供相位屏障校准。",
		"texture": WHITE_AEGIS, "position": Vector2(352, 378),
	},
	"iron_bastion": {
		"name": "铁垒 / IRON BASTION", "role": "普通敌机 · 重装压制型",
		"stats": "耐久 A    机动 D    火力 A\n弱点：背部散热栅 · 转向迟缓 · 过热停机",
		"description": "一台失控的工程机正在巡逻东侧装卸区。\n靠近后可确认遭遇。",
		"texture": IRON_BASTION, "position": Vector2(970, 390),
	},
	"redline_seraph": {
		"name": "赤线炽天 / REDLINE SERAPH", "role": "主角座驾 · 高输出突击型",
		"stats": "耐久 B    机动 S    火力 S\n特性：赤线超载 · 光刃翼阵 · 神经同步",
		"description": "凌霁当前驾驶的实验型机甲。\n移动时按行进方向切换地图姿态。",
		"texture": REDLINE_SERAPH, "position": Vector2(620, 540),
	},
}

const PATROL_LEFT_X: float = 835.0
const PATROL_RIGHT_X: float = 1085.0
const PATROL_SPEED: float = 54.0

var mode: Mode = Mode.EXPLORE
var player: CharacterBody2D
var player_map_sprite: AnimatedSprite2D
var exhibits: Dictionary = {}
var enemy_unit: Node2D
var enemy_direction: float = 1.0
var enemy_engaged: bool = false
var interaction_tip: Label
var detail_panel: PanelContainer
var detail_icon: TextureRect
var detail_title: Label
var detail_role: Label
var detail_stats: Label
var detail_description: Label
var detail_choices: VBoxContainer


func _ready() -> void:
	_build_background()
	_build_world()
	_build_hud()
	get_node("/root/GameState").saved_location = "command"


func _process(delta: float) -> void:
	_update_player_direction()
	_update_enemy_patrol(delta)
	if mode != Mode.EXPLORE:
		return
	var target: String = _nearest_target()
	if target == "white_aegis":
		interaction_tip.text = "[ E ] 联络白曜神盾 · 友方支援"
	elif target == "iron_bastion":
		interaction_tip.text = "[ E ] 敌机接触 · 铁垒巡逻单位"
	elif target == "exit":
		interaction_tip.text = "[ E ] 返回基地指挥中心"
	else:
		interaction_tip.text = "WASD / 方向键驾驶赤线炽天   ·   E 交互   ·   ESC 返回"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if mode == Mode.MODAL:
			_close_detail()
		else:
			_return_to_command()
		return
	if mode == Mode.EXPLORE and event.is_action_pressed("interact"):
		var target: String = _nearest_target()
		if target == "white_aegis":
			_open_detail(target)
		elif target == "iron_bastion":
			_open_enemy_contact()
		elif target == "exit":
			_return_to_command()


func _build_background() -> void:
	var image := TextureRect.new()
	image.name = "MechYardMap"
	image.texture = _load_texture(MAP_BACKGROUND_PATH, BACKGROUND)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.size = Vector2(1280, 720)
	image.z_index = -20
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.06, 0.08)
	shade.size = Vector2(1280, 720)
	shade.z_index = -19
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)


func _build_world() -> void:
	y_sort_enabled = true
	_build_collision()
	_build_map_landmarks()
	var white_unit := Node2D.new()
	white_unit.name = "WhiteAegisSupport"
	white_unit.position = EXHIBITS.white_aegis.position
	white_unit.add_child(_make_map_sprite(_load_texture(WHITE_MAP_PATH, WHITE_AEGIS), 82.0, "down", ResourceLoader.exists(WHITE_MAP_PATH)))
	white_unit.add_child(_unit_label("白曜神盾 · 支援", Color("bdeaff")))
	add_child(white_unit)
	exhibits.white_aegis = {"node": white_unit, "icon": white_unit.get_child(0)}

	enemy_unit = Node2D.new()
	enemy_unit.name = "IronBastionPatrol"
	enemy_unit.position = EXHIBITS.iron_bastion.position
	enemy_unit.add_child(_make_map_sprite(_load_texture(IRON_MAP_PATH, IRON_BASTION), 94.0, "left", ResourceLoader.exists(IRON_MAP_PATH)))
	enemy_unit.add_child(_unit_label("◆ 敌机 · 铁垒", Color("ff9a7c")))
	add_child(enemy_unit)
	exhibits.iron_bastion = {"node": enemy_unit, "icon": enemy_unit.get_child(0)}

	var exit := Node2D.new()
	exit.name = "Exit"
	exit.position = Vector2(126, 574)
	var exit_label := _label("⇅  基地闸门", 16, Color("64eee5"))
	exit_label.position = Vector2(-70, -28)
	exit_label.size = Vector2(180, 36)
	exit.add_child(exit_label)
	add_child(exit)
	exhibits.exit = {"node": exit}

	player = CharacterBody2D.new()
	player.name = "RedlineSeraphPlayer"
	player.set_script(PLAYER_SCRIPT)
	player.position = EXHIBITS.redline_seraph.position
	player.movement_bounds = Rect2(72, 166, 1136, 456)
	player.speed = 155.0
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	collision.shape = shape
	player.add_child(collision)
	add_child(player)
	player.actor_sprite.hide()
	player_map_sprite = _make_map_sprite(_load_texture(REDLINE_MAP_PATH, REDLINE_SERAPH), 92.0, "down", ResourceLoader.exists(REDLINE_MAP_PATH))
	player_map_sprite.name = "RedlineMapArt"
	player.add_child(player_map_sprite)
	exhibits.redline_seraph = {"node": player, "icon": player_map_sprite}


func _build_collision() -> void:
	var blockers: Array[Rect2] = [
		Rect2(430, 414, 420, 74),
		Rect2(1120, 294, 88, 172),
	]
	for area: Rect2 in blockers:
		var body := StaticBody2D.new()
		body.position = area.get_center()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = area.size
		collision.shape = shape
		body.add_child(collision)
		add_child(body)


func _build_map_landmarks() -> void:
	var landmarks: Array[Dictionary] = [
		{"text": "A-03  开放装卸区", "position": Vector2(872, 182)},
		{"text": "◇  相位补给桩", "position": Vector2(330, 196)},
		{"text": "警戒线 / PATROL LIMIT", "position": Vector2(914, 594)},
	]
	for data: Dictionary in landmarks:
		var marker := _label(data.text, 13, Color("8cb8c7"))
		marker.position = data.position
		marker.add_theme_color_override("font_outline_color", Color("07151f"))
		marker.add_theme_constant_override("outline_size", 4)
		add_child(marker)


func _make_map_sprite(texture: Texture2D, target_height: float, initial_direction: String, allow_sheet: bool = true) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var texture_size: Vector2 = texture.get_size()
	var valid_sheet: bool = allow_sheet and texture_size.x >= 4.0 and texture_size.y >= 4.0 and is_equal_approx(texture_size.x, texture_size.y)
	var directions: Dictionary = {"down": 0, "left": 1, "right": 2, "up": 3}
	if valid_sheet:
		var cell_size: Vector2 = texture_size / 2.0
		for direction: String in directions:
			frames.add_animation(direction)
			frames.set_animation_loop(direction, false)
			var index: int = directions[direction]
			var frame := AtlasTexture.new()
			frame.atlas = texture
			frame.region = Rect2(Vector2(index % 2, index / 2) * cell_size, cell_size)
			frames.add_frame(direction, frame)
		sprite.scale = Vector2.ONE * (target_height / cell_size.y)
	else:
		for direction: String in directions:
			frames.add_animation(direction)
			frames.set_animation_loop(direction, false)
			frames.add_frame(direction, texture)
		sprite.scale = Vector2.ONE * (target_height / maxf(texture_size.y, 1.0))
	sprite.sprite_frames = frames
	sprite.animation = initial_direction
	sprite.position.y = -target_height * 0.43
	return sprite


func _update_player_direction() -> void:
	if not is_instance_valid(player_map_sprite) or not is_instance_valid(player):
		return
	var velocity: Vector2 = player.velocity
	if velocity.is_zero_approx():
		return
	if absf(velocity.x) > absf(velocity.y):
		player_map_sprite.animation = "right" if velocity.x > 0.0 else "left"
	else:
		player_map_sprite.animation = "down" if velocity.y > 0.0 else "up"


func _update_enemy_patrol(delta: float) -> void:
	if not is_instance_valid(enemy_unit) or mode != Mode.EXPLORE or enemy_engaged:
		return
	enemy_unit.position.x += enemy_direction * PATROL_SPEED * delta
	if enemy_unit.position.x >= PATROL_RIGHT_X:
		enemy_unit.position.x = PATROL_RIGHT_X
		enemy_direction = -1.0
	elif enemy_unit.position.x <= PATROL_LEFT_X:
		enemy_unit.position.x = PATROL_LEFT_X
		enemy_direction = 1.0
	var sprite: AnimatedSprite2D = exhibits.iron_bastion.icon
	sprite.animation = "right" if enemy_direction > 0.0 else "left"


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var title_panel := PanelContainer.new()
	title_panel.position = Vector2(28, 24)
	title_panel.size = Vector2(430, 78)
	title_panel.add_theme_stylebox_override("panel", _box(Color(0.025, 0.07, 0.1, 0.91), Color("315263"), 1, 5))
	title_panel.add_child(_label("M2 · 天穹校验坪\nSKYLINE PROVING GROUND", 18, Color("edfaff")))
	layer.add_child(title_panel)
	var objective := PanelContainer.new()
	objective.position = Vector2(868, 24)
	objective.size = Vector2(384, 94)
	objective.add_theme_stylebox_override("panel", _box(Color(0.025, 0.07, 0.1, 0.91), Color("315263"), 1, 5))
	objective.add_child(_label("区域目标\n识别友军 · 规避或接触巡逻敌机", 14, Color("b8dce5")))
	layer.add_child(objective)
	var tip_panel := PanelContainer.new()
	tip_panel.position = Vector2(315, 648)
	tip_panel.size = Vector2(650, 48)
	tip_panel.add_theme_stylebox_override("panel", _box(Color(0.025, 0.07, 0.1, 0.94), Color("32e6db"), 1, 5))
	interaction_tip = _label("", 15, Color("64eee5"))
	interaction_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_tip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tip_panel.add_child(interaction_tip)
	layer.add_child(tip_panel)
	_build_detail_panel(layer)


func _build_detail_panel(layer: CanvasLayer) -> void:
	detail_panel = PanelContainer.new()
	detail_panel.visible = false
	detail_panel.position = Vector2(215, 142)
	detail_panel.size = Vector2(850, 438)
	detail_panel.add_theme_stylebox_override("panel", _box(Color("091722"), Color("64eee5"), 1, 9))
	layer.add_child(detail_panel)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 22)
	detail_panel.add_child(body)
	detail_icon = TextureRect.new()
	detail_icon.custom_minimum_size = Vector2(290, 370)
	detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	body.add_child(detail_icon)
	var copy := VBoxContainer.new()
	copy.custom_minimum_size.x = 470
	copy.add_theme_constant_override("separation", 10)
	body.add_child(copy)
	copy.add_child(_label("TACTICAL LINK / LOCAL", 12, Color("64eee5")))
	detail_title = _label("", 27, Color("fff0cf"))
	copy.add_child(detail_title)
	detail_role = _label("", 16, Color("e6a84c"))
	copy.add_child(detail_role)
	copy.add_child(HSeparator.new())
	detail_stats = _label("", 16, Color("d8e8ed"))
	copy.add_child(detail_stats)
	detail_description = _label("", 14, Color("a9c3cc"))
	detail_description.custom_minimum_size = Vector2(470, 82)
	detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(detail_description)
	detail_choices = VBoxContainer.new()
	detail_choices.add_theme_constant_override("separation", 6)
	copy.add_child(detail_choices)


func _nearest_target() -> String:
	var nearest: String = ""
	var distance: float = 112.0
	for id: String in ["white_aegis", "iron_bastion", "exit"]:
		var candidate: float = player.position.distance_to(exhibits[id].node.position)
		if candidate < distance:
			nearest = id
			distance = candidate
	return nearest


func _open_detail(id: String) -> void:
	var data: Dictionary = EXHIBITS[id]
	detail_icon.texture = data.texture
	detail_title.text = data.name
	detail_role.text = data.role
	detail_stats.text = data.stats
	detail_description.text = data.description
	_clear_choices()
	_add_choice("关闭", _close_detail)
	detail_panel.show()
	mode = Mode.MODAL
	player.set_controls_enabled(false)


func _open_enemy_contact() -> void:
	_open_detail("iron_bastion")
	detail_description.text = "敌方火控雷达已锁定赤线炽天。\n可利用它转向迟缓的窗口切入散热核，或暂时后退绕行。"
	_clear_choices()
	_add_choice("进入战斗", _start_patrol_encounter)
	_add_choice("后退", _close_detail)


func _start_patrol_encounter() -> void:
	enemy_engaged = true
	detail_title.text = "遭遇已确认 / ENCOUNTER READY"
	detail_role.text = "铁垒已进入战斗距离"
	detail_stats.text = "战术建议：侧向突进，攻击背部散热栅。"
	detail_description.text = "巡逻机停止移动并展开双臂火器。\n已建立地图遭遇入口，可在此接入独立机甲战斗场景。"
	_clear_choices()
	_add_choice("脱离接触", _end_patrol_encounter)


func _end_patrol_encounter() -> void:
	enemy_engaged = false
	_close_detail()
	player.position.x = maxf(player.position.x - 92.0, player.movement_bounds.position.x)


func _close_detail() -> void:
	detail_panel.hide()
	mode = Mode.EXPLORE
	player.set_controls_enabled(true)


func _clear_choices() -> void:
	for child: Node in detail_choices.get_children():
		detail_choices.remove_child(child)
		child.queue_free()


func _add_choice(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 34.0
	button.pressed.connect(callback)
	detail_choices.add_child(button)


func _return_to_command() -> void:
	get_node("/root/GameState").saved_location = "command"
	get_node("/root/GameState").save_progress()
	get_tree().change_scene_to_file("res://scenes/exploration.tscn")


func _load_texture(path: String, fallback: Texture2D) -> Texture2D:
	if ResourceLoader.exists(path):
		var loaded: Resource = load(path)
		if loaded is Texture2D:
			return loaded as Texture2D
	return fallback


func _unit_label(text: String, color: Color) -> Label:
	var label := _label(text, 13, color)
	label.position = Vector2(-100, -105)
	label.size = Vector2(200, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color("07151f"))
	label.add_theme_constant_override("outline_size", 5)
	return label


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	return label


func _box(color: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style
