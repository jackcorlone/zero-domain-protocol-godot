extends Control

const BACKGROUND := preload("res://assets/environments/b7-battle-2d-v1.png")

var settings_panel: PanelContainer
var new_game_confirmation: ConfirmationDialog
var save_feedback: Label


func _ready() -> void:
	preload("res://scripts/game_settings.gd").apply_saved()
	_build_interface()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and settings_panel.visible:
		settings_panel.hide()
		get_viewport().set_input_as_handled()


func _build_interface() -> void:
	var background := TextureRect.new()
	background.texture = BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.06, 0.62)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var accent := ColorRect.new()
	accent.color = Color("32e6db")
	accent.position = Vector2(72, 88)
	accent.size = Vector2(4, 430)
	add_child(accent)

	var content := VBoxContainer.new()
	content.position = Vector2(104, 84)
	content.size = Vector2(520, 550)
	content.add_theme_constant_override("separation", 12)
	add_child(content)

	content.add_child(_label("SITE OMEGA // 终端接入已授权", 15, Color("64eee5")))
	content.add_child(_label("零域协议", 66, Color("edfaff")))
	content.add_child(_label("NULL ZONE PROTOCOL", 20, Color("8ba7b8")))

	var gap := Control.new()
	gap.custom_minimum_size.y = 24
	content.add_child(gap)
	content.add_child(_label("公元 2057 年，北极圈深层基地的核心突然失联。\n你是唯一被系统允许进入零域的人。", 18, Color("c6d8df")))

	var button_gap := Control.new()
	button_gap.custom_minimum_size.y = 26
	content.add_child(button_gap)

	var start_button := _menu_button("01   开始游戏", "进入 SITE OMEGA", true)
	start_button.pressed.connect(_request_new_game)
	content.add_child(start_button)
	var continue_button := _menu_button("继续游戏", "恢复最近一次探索进度", false)
	continue_button.custom_minimum_size.y = 60
	continue_button.disabled = not FileAccess.file_exists(get_node("/root/GameState").save_path)
	continue_button.pressed.connect(_continue_game)
	content.add_child(continue_button)

	var settings_button := _menu_button("02   游戏设置", "音频与显示", false)
	settings_button.pressed.connect(_open_settings)
	content.add_child(settings_button)
	save_feedback = _label("探索和对话结束时自动保存；战斗中保留入场前进度。", 12, Color("9cb4bf"))
	content.add_child(save_feedback)
	new_game_confirmation = ConfirmationDialog.new()
	new_game_confirmation.dialog_text = "开始新游戏将覆盖本版本的探索存档。确定重新开始？"
	new_game_confirmation.confirmed.connect(_start_game)
	add_child(new_game_confirmation)

	var footer := Label.new()
	footer.text = "GODOT VERTICAL SLICE 0.1  //  ORIGINAL SCI-FI RPG"
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color("64808f"))
	footer.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	footer.position = Vector2(72, 682)
	add_child(footer)

	_build_settings_panel()


func _build_settings_panel() -> void:
	settings_panel = PanelContainer.new()
	settings_panel.visible = false
	settings_panel.custom_minimum_size = Vector2(460, 340)
	settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	settings_panel.position = Vector2(-230, -170)
	settings_panel.add_theme_stylebox_override("panel", _box(Color("0b1824"), Color("32e6db"), 1, 10))
	add_child(settings_panel)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.add_theme_constant_override("margin_left", 28)
	body.add_theme_constant_override("margin_right", 28)
	body.add_theme_constant_override("margin_top", 24)
	body.add_theme_constant_override("margin_bottom", 24)
	settings_panel.add_child(body)
	body.add_child(_label("SYSTEM / OPTIONS", 13, Color("64eee5")))
	body.add_child(_label("游戏设置", 30, Color("edfaff")))

	preload("res://scripts/game_settings.gd").build_controls(body)

	var close_button := Button.new()
	close_button.text = "保存并返回"
	close_button.custom_minimum_size.y = 44
	close_button.pressed.connect(settings_panel.hide)
	body.add_child(close_button)


func _menu_button(title: String, subtitle: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = "%s\n      %s" % [title, subtitle]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(430, 76)
	button.add_theme_font_size_override("font_size", 18)
	var base := Color("12313c") if primary else Color("111f2b")
	button.add_theme_stylebox_override("normal", _box(base, Color("32e6db") if primary else Color("315263"), 1, 4))
	button.add_theme_stylebox_override("hover", _box(Color("174753"), Color("64eee5"), 2, 4))
	button.add_theme_stylebox_override("pressed", _box(Color("0e2832"), Color("32e6db"), 2, 4))
	return button


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
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


func _start_game() -> void:
	get_node("/root/GameState").reset()
	get_node("/root/GameState").persistence_enabled = true
	get_tree().change_scene_to_file("res://scenes/exploration.tscn")


func _request_new_game() -> void:
	if FileAccess.file_exists(get_node("/root/GameState").save_path):
		new_game_confirmation.popup_centered()
	else:
		_start_game()


func _continue_game() -> void:
	if get_node("/root/GameState").load_progress():
		get_tree().change_scene_to_file(get_node("/root/GameState").saved_scene())
	else:
		save_feedback.text = "读取失败或存档不兼容。原存档未修改；可选择开始新游戏。"


func _open_settings() -> void:
	settings_panel.show()

