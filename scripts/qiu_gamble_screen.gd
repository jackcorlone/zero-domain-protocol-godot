class_name QiuGambleScreen
extends CanvasLayer

signal qiu_arrested
signal closed

const RULES := preload("res://scripts/pirate_arc_rules.gd")

var game_state: ZeroDomainGameState
var selected_direction: String = ""
var root: PanelContainer
var prompt_label: Label
var die_label: Label
var roll_button: Button


func _ready() -> void:
	_build_interface()
	root.hide()


func open(state: ZeroDomainGameState) -> void:
	game_state = state
	selected_direction = ""
	root.show()
	_refresh()


func choose_direction(direction: String) -> bool:
	if direction not in RULES.DIRECTIONS or game_state == null:
		return false
	selected_direction = direction
	die_label.text = "已选择：%s。掷骰确认。" % _direction_name(direction)
	roll_button.disabled = false
	return true


func roll_die(forced_die: int = 0) -> String:
	if game_state == null or selected_direction.is_empty():
		return "invalid"
	var die: int = forced_die if forced_die in range(1, 7) else randi_range(1, 6)
	var result: String = RULES.resolve_gamble_round(game_state.pirate_arc, selected_direction, die)
	die_label.text = "骰面 %d · %s" % [die, _result_text(result)]
	selected_direction = ""
	roll_button.disabled = true
	if result == "qiu_arrested":
		qiu_arrested.emit()
	else:
		_refresh(false)
	return result


func _refresh(clear_result: bool = true) -> void:
	var round_index: int = int(game_state.pirate_arc.gamble_round)
	prompt_label.text = ["第一局 · 庄家暗仓：选择任意审计方向并掷骰。", "第二局 · 向上且骰点3—6成功。", "第三局 · 向左且骰点1—4完成反转。", "清算完成：执法队已控制裘盛。 "][round_index]
	if clear_result:
		die_label.text = "先按方向箭头，再掷六面骰。"
	roll_button.disabled = selected_direction.is_empty()


func _build_interface() -> void:
	root = PanelContainer.new()
	root.position = Vector2(330, 150)
	root.size = Vector2(620, 420)
	add_child(root)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)
	body.add_child(_label("红钻清算 · 三局赌战", 28))
	prompt_label = _label("", 18)
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(prompt_label)
	var arrows := HBoxContainer.new()
	body.add_child(arrows)
	for direction: String in RULES.DIRECTIONS:
		var button := Button.new()
		button.text = {"up": "↑ 上", "right": "→ 右", "down": "↓ 下", "left": "← 左"}[direction]
		button.custom_minimum_size = Vector2(130, 54)
		button.pressed.connect(choose_direction.bind(direction))
		arrows.add_child(button)
	die_label = _label("", 18)
	body.add_child(die_label)
	roll_button = Button.new()
	roll_button.text = "掷骰"
	roll_button.custom_minimum_size.y = 58
	roll_button.pressed.connect(func() -> void: roll_die())
	body.add_child(roll_button)
	var exit_button := Button.new()
	exit_button.text = "暂时离桌"
	exit_button.pressed.connect(func() -> void:
		root.hide()
		closed.emit())
	body.add_child(exit_button)


func _result_text(result: String) -> String:
	return {"lost_first": "庄家优势生效，凌霁首局败北。", "won_second": "溯源成功，凌霁扳回一局。", "qiu_arrested": "追偿链闭合，资金冻结；执法队进场逮捕裘盛。", "retry": "审计方向错误，本局未落槌，可重新选择。"}.get(result, "输入无效。")


func _direction_name(direction: String) -> String:
	return {"up": "上", "right": "右", "down": "下", "left": "左"}.get(direction, "未知")


func _label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	return label
