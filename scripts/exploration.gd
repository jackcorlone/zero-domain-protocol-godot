extends Node2D

enum Mode { EXPLORE, MODAL, BATTLE }

const COMMAND_BACKGROUND := preload("res://assets/environments/command-2d-v1.png")
const B7_BACKGROUND := preload("res://assets/environments/b7-map-2d-v1.png")
const PORTRAIT := preload("res://assets/characters/lyra-portrait-2d-v1.png")
const COMMANDER_ART := preload("res://assets/npcs/commander-2d-v1.png")
const SENTINEL_WORLD := preload("res://assets/enemies/sentinel-2d-v1.png")
const PLAYER_SCRIPT := preload("res://scripts/player.gd")
const BATTLE_SCRIPT := preload("res://scripts/battle_screen.gd")
const CHARACTER_ART := preload("res://scripts/character_art.gd")
const LUO_DIALOGUE := preload("res://scripts/luo_dialogue.gd")
const PIRATE_RULES := preload("res://scripts/pirate_arc_rules.gd")
const WEN_JIAN_ART := preload("res://assets/enemies/wen-jian-combat-v1.png")
const WEN_JIAN_MIRROR_CG := preload("res://assets/story/wen-jian-mirror-incursion-v1.png")
const WEN_JIAN_DEFEAT_CG := preload("res://assets/story/wen-jian-defeat-be-v1.png")
const WEN_JIAN_PRISON_CG := preload("res://assets/story/wen-jian-defeat-prison-v1.png")
const WEN_JIAN_HEGEMONY_CG := preload("res://assets/story/wen-jian-defeat-hegemony-v1.png")
const QIU_PRISON_BE_CG := preload("res://assets/story/qiu-prison-approach-be-v1.png")
const MI_PO_ART := preload("res://assets/npcs/mi-po-fullbody-v1.png")
const MI_PO_PORTRAITS := preload("res://assets/npcs/mi-po-trust-portraits-v1.png")

@onready var game_state: ZeroDomainGameState = get_node("/root/GameState")
var mode: Mode = Mode.EXPLORE
var location_id: String = "command"

var background: TextureRect
var world_shade: ColorRect
var player: CharacterBody2D
var commander: Node2D
var commander_quest_badge: Label
var terminal: Node2D
var supply: Node2D
var command_elevator: Node2D
var b7_elevator: Node2D
var relay: Node2D
var sentinel: Node2D
var wreck: Node2D
var command_collision: StaticBody2D
var b7_collision: StaticBody2D
var interaction_tip: Label
var location_label: Label
var mission_title: Label
var mission_text: Label
var player_status: Label
var character_panel: PanelContainer
var quest_log_label: Label
var dialogue_panel: PanelContainer
var dialogue_header: Label
var dialogue_name: Label
var dialogue_line: Label
var dialogue_text_scroll: ScrollContainer
var dialogue_choices: VBoxContainer
var dialogue_avatar_frame: PanelContainer
var dialogue_avatar: TextureRect
var dialogue_portrait: TextureRect
var map_panel: PanelContainer
var battle_screen: ZeroDomainBattleScreen
var character_portrait: TextureRect
var hud_portrait: TextureRect
var character_stats: Label
var services: VBoxContainer
var character_tabs: TabContainer
var task_summary: Label
var system_feedback: Label
var side_terminal: Node2D
var luo_dialogue: RefCounted
var luo_story_picture: Control
var bad_end_active: bool = false
var puzzle_step: int = 0


func _ready() -> void:
	_build_background()
	_build_world()
	_build_hud()
	_build_battle()
	luo_dialogue = LUO_DIALOGUE.new(self)
	_set_location(game_state.saved_location)


func _process(_delta: float) -> void:
	if mode != Mode.EXPLORE:
		return
	var target: String = _nearest_target()
	if target == "commander":
		interaction_tip.text = "[ E ] 与沈砚交谈"
	elif target == "terminal":
		interaction_tip.text = "[ E ] 读取安全终端"
	elif target == "supply":
		interaction_tip.text = "[ E ] 检查应急补给箱"
	elif target == "command_elevator":
		interaction_tip.text = "[ E ] 电梯 · B7 / H1 飞船舱" if game_state.echo.accepted else "[ E ] 使用 B7 电梯"
	elif target == "relay":
		interaction_tip.text = "[ E ] 操作损坏的控制中继"
	elif target == "sentinel":
		interaction_tip.text = "[ E ] 接触 SENTINEL" if game_state.quest_state >= ZeroDomainGameState.QuestState.RELAY_DECIDED else "先处理控制中继"
	elif target == "wreck":
		interaction_tip.text = "[ E ] 调查 SENTINEL 残骸"
	elif target == "b7_elevator":
		interaction_tip.text = "[ E ] 返回指挥中心"
	elif target == "side_terminal":
		interaction_tip.text = "[ E ] 调查维护支路 / 装备箱"
	else:
		interaction_tip.text = "WASD / 方向键移动   ·   C 人物   ·   M 地图"
	interaction_tip.modulate = Color("64eee5") if target != "" else Color("b3c9d3")


func _unhandled_input(event: InputEvent) -> void:
	if mode == Mode.BATTLE:
		return
	if event.is_action_pressed("ui_cancel"):
		if bad_end_active:
			return
		if mode == Mode.MODAL:
			_close_modals()
		else:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	if mode != Mode.EXPLORE:
		if (event.is_action_pressed("character_panel") and character_panel.visible) or (event.is_action_pressed("map_panel") and map_panel.visible):
			_close_modals()
		return
	if event.is_action_pressed("interact"):
		_interact_with_nearest()
	elif event.is_action_pressed("character_panel"):
		_open_character()
	elif event.is_action_pressed("map_panel"):
		_open_modal(map_panel)


func _interact_with_nearest() -> void:
	match _nearest_target():
		"commander":
			_interact_commander()
		"terminal":
			_interact_terminal()
		"supply":
			_interact_supply()
		"command_elevator":
			_interact_command_elevator()
		"relay":
			_interact_relay()
		"sentinel":
			_interact_sentinel()
		"wreck":
			_interact_wreck()
		"b7_elevator":
			_set_location("command")
		"side_terminal":
			_interact_side_terminal()


func _interact_commander() -> void:
	match game_state.quest_state:
		ZeroDomainGameState.QuestState.NOT_STARTED:
			_show_commander_briefing()
		ZeroDomainGameState.QuestState.RECORD_RECOVERED:
			_report_to_commander()
		ZeroDomainGameState.QuestState.SENTINEL_DEFEATED:
			_show_dialogue("基地指挥官 / COMMANDER", "沈砚", "先回收 Sentinel 的认证记录。没有记录，我无法结算这次任务。")
		ZeroDomainGameState.QuestState.COMPLETE:
			if game_state.ruins.secret_recovered and not game_state.ruins.reported:
				_report_ruins_mission()
			elif game_state.echo.reward_claimed:
				_ruins_briefing()
			else:
				_expedition_briefing()
		_:
			_show_dialogue("基地指挥官 / COMMANDER", "沈砚", "先检查安全终端，再使用东侧电梯进入 B7。")


func _show_commander_briefing() -> void:
	_show_dialogue("基地指挥官 / COMMANDER", "沈砚", "B7 的巡逻节点在六分钟前脱离控制。一台 Sentinel 封锁了收容区，而且它正在使用你的识别码申请核心权限。")
	_add_dialogue_choice("我的识别码为什么会出现在 B7？", _commander_identity_question)
	_add_dialogue_choice("任务目标？", _accept_quest)


func _commander_identity_question() -> void:
	_show_dialogue("基地指挥官 / COMMANDER", "沈砚", "最后一份完整记录还在安全终端。先看记录，再下去；我不想让你对着另一个‘自己’开火。")
	_add_dialogue_choice("返回简报", _show_commander_briefing)


func _accept_quest() -> void:
	game_state.accept_quest()
	_show_dialogue("基地指挥官 / COMMANDER", "沈砚", "终止 Sentinel，回收它的最后一次认证记录，然后回来汇报。B7 的控制中继也许能削弱它，但那会损坏证据。")
	_update_hud()


func _interact_terminal() -> void:
	if game_state.quest_state == ZeroDomainGameState.QuestState.NOT_STARTED:
		_show_dialogue("安全终端 / SECURE TERMINAL", "B7-7A", "需要 Ω-7 临时任务权限。")
	elif game_state.quest_state == ZeroDomainGameState.QuestState.ACCEPTED:
		_show_dialogue("安全终端 / SECURE TERMINAL", "B7-7A 最终记录", "Sentinel 每完成两次常规攻击后，将执行一次高功率破障攻击。控制中继仍可接受本地维护指令。")
		_add_dialogue_choice("下载战术记录", _scan_terminal)
	else:
		_show_dialogue("安全终端 / SECURE TERMINAL", "战术记录已下载", "敌方每第 3 次行动发动重击；提前防御可形成反击窗口。")


func _scan_terminal() -> void:
	if game_state.quest_state == ZeroDomainGameState.QuestState.ACCEPTED:
		game_state.quest_state = ZeroDomainGameState.QuestState.TERMINAL_SCANNED
	_show_dialogue("安全终端 / SECURE TERMINAL", "下载完成", "战术教程已解锁：敌方每第 3 次行动发动重击；提前防御可形成反击窗口。")
	_update_hud()


func _interact_supply() -> void:
	if game_state.quest_state == ZeroDomainGameState.QuestState.NOT_STARTED:
		_show_dialogue("应急补给箱 / SUPPLY", "安全锁定", "任务权限尚未签发。")
	elif game_state.supply_choice != ZeroDomainGameState.SupplyChoice.NONE:
		_show_dialogue("应急补给箱 / SUPPLY", "库存状态", "补给箱已清空。")
	else:
		_show_dialogue("应急补给箱 / SUPPLY", "单次整备", "箱内仅剩一组可用接口。选择后，另一组将因安全锁失效。")
		_add_dialogue_choice("接入医疗凝胶 · HP +140", _choose_supply.bind(ZeroDomainGameState.SupplyChoice.MED_GEL))
		_add_dialogue_choice("接入过载电池 · MP +120", _choose_supply.bind(ZeroDomainGameState.SupplyChoice.BATTERY))
		_add_dialogue_choice("暂不使用", _close_modals)


func _choose_supply(choice: ZeroDomainGameState.SupplyChoice) -> void:
	if not game_state.take_supply(choice):
		return
	var feedback: String = "外骨骼密封层已修复。" if choice == ZeroDomainGameState.SupplyChoice.MED_GEL else "NEX-4 备用电容已充能。"
	_show_dialogue("应急补给箱 / SUPPLY", "整备完成", feedback)
	_update_hud()


func _interact_command_elevator() -> void:
	if game_state.quest_state < ZeroDomainGameState.QuestState.TERMINAL_SCANNED:
		_show_dialogue("电梯系统 / TRANSIT", "B7 导航协议缺失", "请先读取安全终端的最后记录。")
	else:
		if game_state.echo.accepted:
			_show_dialogue("电梯系统 / TRANSIT", "选择目的地", "B7 收容区与 H1 飞船舱均已开放。前往灰潮盆地，请选择 H1。")
		else:
			_show_dialogue("电梯系统 / TRANSIT", "目的地：B7-7A 收容区", "检测到敌对自动单位。")
		_add_dialogue_choice("进入 B7", _set_location.bind("b7"))
		_add_dialogue_choice("返回整备", _close_modals)
		_add_dialogue_choice("M2 · 天穹校验坪", _enter_mech_bay)
		if game_state.echo.accepted:
			_add_dialogue_choice("H1 · 飞船舱", _enter_hangar)


func _interact_relay() -> void:
	if game_state.relay_choice != ZeroDomainGameState.RelayChoice.NONE:
		var status: String = "区域供能已切断，认证缓存不可恢复。" if game_state.relay_choice == ZeroDomainGameState.RelayChoice.CUT_POWER else "握手镜像正在隔离通道内持续记录。"
		_show_dialogue("控制中继 / RELAY", "指令已锁定", status)
		return
	_show_dialogue("控制中继 / RELAY", "LYRA-7 认证握手", "可切断区域供能，或镜像握手并保留完整来源记录。选择一经执行不可撤回。")
	_add_dialogue_choice("切断供能，优先降低威胁", _choose_relay.bind(ZeroDomainGameState.RelayChoice.CUT_POWER))
	_add_dialogue_choice("镜像握手，保留完整证据", _choose_relay.bind(ZeroDomainGameState.RelayChoice.MIRROR_SIGNAL))


func _choose_relay(choice: ZeroDomainGameState.RelayChoice) -> void:
	if game_state.quest_state != ZeroDomainGameState.QuestState.IN_B7 or game_state.relay_choice != ZeroDomainGameState.RelayChoice.NONE:
		return
	game_state.relay_choice = choice
	game_state.quest_state = ZeroDomainGameState.QuestState.RELAY_DECIDED
	relay.modulate = Color("394149") if choice == ZeroDomainGameState.RelayChoice.CUT_POWER else Color.WHITE
	world_shade.color = Color(0.01, 0.03, 0.045, 0.36 if choice == ZeroDomainGameState.RelayChoice.CUT_POWER else 0.04)
	var feedback: String = "供能下降。Sentinel 装甲响应明显减弱，但认证缓存正在丢失。" if choice == ZeroDomainGameState.RelayChoice.CUT_POWER else "握手镜像建立。Sentinel 尚未察觉中继被监听。"
	_show_dialogue("控制中继 / RELAY", "维护指令已执行", feedback)
	_update_hud()


func _interact_sentinel() -> void:
	if game_state.quest_state != ZeroDomainGameState.QuestState.RELAY_DECIDED:
		_show_dialogue("SENTINEL / CONTAINMENT", "身份冲突", "控制中继仍在强化收容协议。先处理本地中继。")
		return
	_show_dialogue("SENTINEL / CONTAINMENT", "身份冲突", "检测到两个 LYRA-7 神经签名。执行收容协议。")
	_add_dialogue_choice("进入战斗", _start_battle)
	_add_dialogue_choice("后退", _close_modals)


func _interact_wreck() -> void:
	if game_state.quest_state != ZeroDomainGameState.QuestState.SENTINEL_DEFEATED:
		return
	if game_state.relay_choice == ZeroDomainGameState.RelayChoice.MIRROR_SIGNAL:
		game_state.record_recovered = ZeroDomainGameState.RecordRecovered.FULL
		_show_dialogue("SENTINEL 残骸 / RECOVERY", "认证记录完整", "伪造的 LYRA-7 握手由核心区下方反向注入。记录末尾只有一行：‘欢迎回来。’")
	else:
		game_state.record_recovered = ZeroDomainGameState.RecordRecovered.PARTIAL
		_show_dialogue("SENTINEL 残骸 / RECOVERY", "认证缓存严重损坏", "仅能确认指令来自基地更深层，发送者身份无法恢复。")
	game_state.quest_state = ZeroDomainGameState.QuestState.RECORD_RECOVERED
	wreck.hide()
	_update_hud()


func _report_to_commander() -> void:
	if location_id != "command":
		return
	var full_record: bool = game_state.record_recovered == ZeroDomainGameState.RecordRecovered.FULL
	if not game_state.claim_quest_reward():
		return
	var report: String = "凌霁：记录保住了。伪造握手来自核心区下方，而且发送者知道我会回来。\n沈砚：把记录从基地网络隔离。凌霁，在我们确认那句话的接收对象之前，不要再让任何系统读取你的神经签名。\n\n静默回路 · 信号已追踪  +320 CR / +250 EXP" if full_record else "凌霁：Sentinel 已停机，但中继断电毁掉了大部分认证缓存。只能确认信号来自基地更深处。\n沈砚：你先控制住了眼前的威胁，这个决定没有错。但从现在开始，我们得假设下面还有一个东西能复制你的身份。\n\n静默回路 · 威胁已隔离  +240 CR / +200 EXP"
	_show_dialogue("任务结算 / MISSION COMPLETE", "沈砚", report)
	_update_hud()


func _nearest_target() -> String:
	if location_id == "command":
		if player.position.distance_to(commander.position) < 115.0:
			return "commander"
		if player.position.distance_to(terminal.position) < 115.0:
			return "terminal"
		if player.position.distance_to(supply.position) < 115.0:
			return "supply"
		if player.position.distance_to(command_elevator.position) < 115.0:
			return "command_elevator"
	else:
		if player.position.distance_to(side_terminal.position) < 100.0:
			return "side_terminal"
		if relay.visible and player.position.distance_to(relay.position) < 125.0:
			return "relay"
		if sentinel.visible and player.position.distance_to(sentinel.position) < 125.0:
			return "sentinel"
		if wreck.visible and player.position.distance_to(wreck.position) < 125.0:
			return "wreck"
		if player.position.distance_to(b7_elevator.position) < 115.0:
			return "b7_elevator"
	return ""


func _set_location(next_location: String) -> void:
	if next_location == "b7" and game_state.quest_state < ZeroDomainGameState.QuestState.TERMINAL_SCANNED:
		return
	if is_instance_valid(dialogue_panel):
		_close_modals()
	location_id = next_location
	services.hide()
	side_terminal.visible = location_id == "b7"
	command_collision.collision_layer = 1 if location_id == "command" else 0
	b7_collision.collision_layer = 1 if location_id == "b7" else 0
	if location_id == "command":
		background.texture = COMMAND_BACKGROUND
		world_shade.color = Color(0.01, 0.03, 0.045, 0.02)
		player.position = Vector2(635, 486)
		commander.show()
		terminal.show()
		supply.show()
		command_elevator.show()
		b7_elevator.hide()
		relay.hide()
		sentinel.hide()
		wreck.hide()
	else:
		background.texture = B7_BACKGROUND
		world_shade.color = Color(0.01, 0.03, 0.045, 0.36 if game_state.relay_choice == ZeroDomainGameState.RelayChoice.CUT_POWER else 0.04)
		player.position = Vector2(210, 500)
		commander.hide()
		terminal.hide()
		supply.hide()
		command_elevator.hide()
		b7_elevator.show()
		relay.show()
		relay.modulate = Color("394149") if game_state.relay_choice == ZeroDomainGameState.RelayChoice.CUT_POWER else Color.WHITE
		if game_state.quest_state == ZeroDomainGameState.QuestState.TERMINAL_SCANNED:
			game_state.quest_state = ZeroDomainGameState.QuestState.IN_B7
		sentinel.visible = game_state.quest_state >= ZeroDomainGameState.QuestState.IN_B7 and game_state.quest_state < ZeroDomainGameState.QuestState.SENTINEL_DEFEATED
		wreck.visible = game_state.quest_state == ZeroDomainGameState.QuestState.SENTINEL_DEFEATED
	_update_hud()


func _start_battle() -> void:
	if game_state.quest_state != ZeroDomainGameState.QuestState.RELAY_DECIDED:
		return
	_close_modals()
	game_state.quest_state = ZeroDomainGameState.QuestState.BATTLE_IN_PROGRESS
	mode = Mode.BATTLE
	player.call("set_controls_enabled", false)
	battle_screen.setup(game_state)


func _on_battle_won() -> void:
	if battle_screen.encounter_id != "main":
		if mode != Mode.BATTLE:
			return
		if battle_screen.encounter_id == "practice":
			game_state.grant_reward(20, 90)
		elif battle_screen.encounter_id == "side":
			game_state.side_patrol_defeated = true
		elif battle_screen.encounter_id == "pirate_guard_1":
			game_state.clear_boarding_wave(0)
		elif battle_screen.encounter_id == "pirate_guard_2":
			game_state.clear_boarding_wave(1)
		_close_modals()
		_update_hud()
		if battle_screen.encounter_id == "wen_jian":
			_show_dialogue("镜中入侵 / COMPLETE", "凌霁", "闻缄再次收紧魂丝时，澄明手环将真实脉搏、时间与受害者签名沿同一条控制链反写。控制核心过载，闻缄被自己的神经接口锁在中继椅上；凌霁保留生命维持，把他与伪造命令签名一并交给医疗队与执法队。\n\n凌霁：我会记得他们，但不会让你替他们说话。\n\n获得「真实指令校验签名」，将用于后续蓝星防线。")
			_add_dialogue_choice("前往葬潮号主炮脊柱 · 断舰庭", _enter_finale)
		if battle_screen.encounter_id == "side":
			_interact_side_terminal()
		return
	if game_state.quest_state != ZeroDomainGameState.QuestState.BATTLE_IN_PROGRESS:
		return
	game_state.quest_state = ZeroDomainGameState.QuestState.SENTINEL_DEFEATED
	sentinel.hide()
	wreck.show()
	mode = Mode.EXPLORE
	player.call("set_controls_enabled", true)
	_update_hud()


func _on_battle_retreated() -> void:
	if battle_screen.encounter_id == "main":
		game_state.quest_state = ZeroDomainGameState.QuestState.RELAY_DECIDED
	mode = Mode.EXPLORE
	player.call("set_controls_enabled", true)
	_update_hud()


func _on_player_defeated() -> void:
	if battle_screen.encounter_id == "wen_jian":
		bad_end_active = true
		mode = Mode.MODAL
		player.call("set_controls_enabled", false)
		_show_wen_bad_end_page(0)
		return
	if battle_screen.encounter_id != "demo":
		game_state.recover_after_defeat()
	if battle_screen.encounter_id == "main":
		game_state.quest_state = ZeroDomainGameState.QuestState.RELAY_DECIDED
	mode = Mode.EXPLORE
	player.call("set_controls_enabled", true)
	_set_location("command")


func _show_wen_bad_end_page(page: int) -> void:
	var headers: Array[String] = ["BAD END / 借来的声音", "BAD END / 静默隔离", "FINAL DARKNESS / 万声归寂", "BAD END / 最后的囚徒"]
	var speakers: Array[String] = ["系统记录", "凌霁", "宇宙联合档案 · 最终记录", "裘盛 / 金腹"]
	var lines: Array[String] = [
		"身份校验通过：凌霁 / LYRA-7。蓝星联合防线接受了伪造的最高优先级撤防指令。\n\n沈砚：“凌霁，校验词不对。那不是你的命令——立刻断开！”\n闻缄：“我从未需要你相信我。我只需要防线相信你。”",
		"凌霁被转移到葬潮号深层隔离舱。武器与通讯被收走，澄明手环只剩微弱脉冲。闻缄得到的是她的认证副本，不是她的意志。\n\n凌霁：“只要我还记得哪一道命令不是我的，你的网络就不是闭环。”",
		"蓝星星核被写入葬潮号的所有权链。岳沉戈以舰队威慑拒绝接入者，闻缄让各文明接受伪造命令，裘盛买下并替换剩余节点。\n\n宇宙没有在一夜间沉默——它只是再也无法确认，自己听见的声音属于谁。此结局不会写入进度。",
		"伪造的司法移交令让押送舰改变航线，裘盛重新取得葬潮号囚区权限。他沿着漫长监区走向凌霁所在的隔离门。\n\n裘盛：“哟，我们美丽的女战士，想过自己也会有今天吗？”\n\n镜头在他抵达之前切黑。牢门上的青蓝脉冲仍在计数。此结局不会写入进度。",
	]
	var pictures: Array[Texture2D] = [WEN_JIAN_DEFEAT_CG, WEN_JIAN_PRISON_CG, WEN_JIAN_HEGEMONY_CG, QIU_PRISON_BE_CG]
	var next_page: int = clampi(page, 0, pictures.size() - 1)
	_show_dialogue(headers[next_page], speakers[next_page], lines[next_page])
	if next_page < pictures.size() - 1:
		_add_dialogue_choice("下一幕", _show_wen_bad_end_page.bind(next_page + 1))
		_show_wen_bad_end_picture(pictures[next_page], headers[next_page], speakers[next_page], lines[next_page], "下一幕", _show_wen_bad_end_page.bind(next_page + 1))
	else:
		_add_dialogue_choice("读取最近安全存档 · 千声室门外", _reload_wen_checkpoint)
		_show_wen_bad_end_picture(pictures[next_page], headers[next_page], speakers[next_page], lines[next_page], "读取最近安全存档 · 千声室门外", _reload_wen_checkpoint)


func _show_wen_bad_end_picture(texture: Texture2D, header: String, speaker: String, line: String, button_text: String, callback: Callable) -> void:
	_clear_luo_story_picture()
	var picture := TextureRect.new()
	picture.size = Vector2(1280, 720)
	picture.texture = texture
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.mouse_filter = Control.MOUSE_FILTER_STOP
	picture.z_index = 50
	dialogue_panel.get_parent().add_child(picture)
	luo_story_picture = picture
	dialogue_panel.hide()
	dialogue_portrait.hide()

	var caption := PanelContainer.new()
	caption.position = Vector2(40, 535)
	caption.size = Vector2(1200, 165)
	caption.add_theme_stylebox_override("panel", _box(Color(0.025, 0.055, 0.09, 0.96), Color("7a58b5"), 1, 6))
	picture.add_child(caption)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 4)
	caption.add_child(body)
	body.add_child(_label(header, 13, Color("ba91ff")))
	body.add_child(_label(speaker, 19, Color("edfaff")))
	var summary := _label(line, 14, Color("cbd9e5"))
	summary.max_lines_visible = 3
	summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	body.add_child(summary)
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size.y = 30
	button.pressed.connect(callback)
	body.add_child(button)


func _reload_wen_checkpoint() -> void:
	bad_end_active = false
	if game_state.load_progress():
		get_tree().change_scene_to_file(game_state.saved_scene())
	else:
		game_state.reset()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _enter_finale() -> void:
	if not game_state.begin_finale():
		_show_dialogue("归潮 / LOCKED", "任务终端", "必须先击败闻缄并取得真实指令校验签名。")
		return
	game_state.save_progress()
	get_tree().change_scene_to_file("res://scenes/finale.tscn")


func _open_modal(panel: PanelContainer) -> void:
	if panel != dialogue_panel:
		_clear_luo_story_picture()
	services.hide()
	character_panel.hide()
	dialogue_panel.hide()
	map_panel.hide()
	if panel != dialogue_panel:
		dialogue_portrait.hide()
	panel.show()
	mode = Mode.MODAL
	player.call("set_controls_enabled", false)


func _close_modals() -> void:
	_clear_luo_story_picture()
	character_panel.hide()
	dialogue_panel.hide()
	dialogue_portrait.hide()
	map_panel.hide()
	mode = Mode.EXPLORE
	services.hide()
	player.call("set_controls_enabled", true)
	game_state.save_progress()


func _build_background() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -1
	add_child(layer)
	background = TextureRect.new()
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(background)
	world_shade = ColorRect.new()
	world_shade.color = Color(0.01, 0.03, 0.045, 0.02)
	world_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(world_shade)


func _build_world() -> void:
	y_sort_enabled = true
	player = CharacterBody2D.new()
	player.name = "LYRA7"
	player.set_script(PLAYER_SCRIPT)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 9.0
	collision.shape = shape
	player.add_child(collision)
	add_child(player)

	commander = _marker("沈砚", Vector2(762, 444), Color("e6a84c"))
	var commander_sprite := Sprite2D.new()
	commander_sprite.texture = COMMANDER_ART
	commander_sprite.scale = Vector2.ONE * (64.0 / COMMANDER_ART.get_height())
	commander_sprite.position = Vector2(0, -29)
	commander.add_child(commander_sprite)
	commander_quest_badge = _label("!", 30, Color("ffd35a"))
	commander_quest_badge.position = Vector2(-14, -112)
	commander_quest_badge.size = Vector2(28, 36)
	commander_quest_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	commander_quest_badge.add_theme_color_override("font_outline_color", Color("402c09"))
	commander_quest_badge.add_theme_constant_override("outline_size", 6)
	commander.add_child(commander_quest_badge)
	terminal = _marker("安全终端", Vector2(447, 328), Color("64eee5"))
	supply = _marker("应急补给", Vector2(487, 619), Color("7edb9a"))
	command_elevator = _marker("B7 电梯", Vector2(1165, 415), Color("64eee5"))
	b7_elevator = _marker("返回指挥中心", Vector2(148, 566), Color("64eee5"))
	relay = _marker("损坏的中继", Vector2(409, 397), Color("e6a84c"))
	side_terminal = _marker("维护支路 · 装备箱", Vector2(660, 564), Color("e6a84c"))
	add_child(side_terminal)
	add_child(commander)
	add_child(terminal)
	add_child(supply)
	add_child(command_elevator)
	add_child(b7_elevator)
	add_child(relay)

	sentinel = Node2D.new()
	sentinel.name = "Sentinel"
	sentinel.position = Vector2(875, 413)
	var enemy_sprite := Sprite2D.new()
	enemy_sprite.texture = SENTINEL_WORLD
	enemy_sprite.scale = Vector2.ONE * (74.0 / SENTINEL_WORLD.get_height())
	enemy_sprite.position = Vector2(0, -35)
	sentinel.add_child(enemy_sprite)
	var enemy_label := _label("失控哨兵", 13, Color("ffd2bd"))
	enemy_label.position = Vector2(-90, -97)
	enemy_label.size = Vector2(180, 24)
	enemy_label.add_theme_color_override("font_outline_color", Color("17353f"))
	enemy_label.add_theme_constant_override("outline_size", 4)
	enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	sentinel.add_child(enemy_label)
	add_child(sentinel)
	wreck = _marker("×  SENTINEL 残骸", Vector2(875, 413), Color("ff8b73"))
	add_child(wreck)
	command_collision = _map_collision([
		Rect2(35, 0, 1200, 137), Rect2(668, 292, 185, 94),
		Rect2(422, 246, 43, 64), Rect2(444, 548, 80, 63),
		Rect2(1100, 280, 134, 111),
	])
	b7_collision = _map_collision([
		Rect2(35, 0, 1200, 153), Rect2(373, 270, 70, 111),
		Rect2(1155, 165, 80, 398), Rect2(46, 443, 108, 105),
	])


func _map_collision(rectangles: Array[Rect2]) -> StaticBody2D:
	var body := StaticBody2D.new()
	for rect: Rect2 in rectangles:
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		var collision := CollisionShape2D.new()
		collision.shape = shape
		collision.position = rect.get_center()
		body.add_child(collision)
	add_child(body)
	return body


func _marker(text: String, marker_position: Vector2, color: Color) -> Node2D:
	var node := Node2D.new()
	node.position = marker_position
	var marker_label := _label(text, 13, color.lightened(0.25))
	marker_label.position = Vector2(-90, -82)
	marker_label.size = Vector2(180, 24)
	marker_label.add_theme_color_override("font_outline_color", Color("17353f"))
	marker_label.add_theme_constant_override("outline_size", 4)
	marker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marker_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	node.add_child(marker_label)
	return node


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var top := PanelContainer.new()
	top.position = Vector2(16, 16)
	top.size = Vector2(310, 64)
	top.add_theme_stylebox_override("panel", _box(Color(0.025, 0.07, 0.1, 0.9), Color("315263"), 1, 5))
	layer.add_child(top)
	location_label = _label("", 14, Color("edfaff"))
	top.add_child(location_label)

	var mission := PanelContainer.new()
	mission.position = Vector2(16, 90)
	mission.size = Vector2(310, 105)
	mission.add_theme_stylebox_override("panel", _box(Color(0.025, 0.07, 0.1, 0.88), Color("315263"), 1, 5))
	layer.add_child(mission)
	var mission_box := VBoxContainer.new()
	mission.add_child(mission_box)
	mission_box.add_child(_label("当前任务 / MAIN", 12, Color("64eee5")))
	mission_title = _label("", 19, Color("edfaff"))
	mission_box.add_child(mission_title)
	mission_text = _label("", 14, Color("b3c9d3"))
	mission_box.add_child(mission_text)

	var interaction_panel := PanelContainer.new()
	interaction_panel.position = Vector2(420, 650)
	interaction_panel.size = Vector2(430, 52)
	interaction_panel.add_theme_stylebox_override("panel", _box(Color(0.025, 0.07, 0.1, 0.9), Color("315263"), 1, 5))
	layer.add_child(interaction_panel)
	interaction_tip = _label("", 14, Color("b3c9d3"))
	interaction_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_tip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interaction_panel.add_child(interaction_tip)

	var player_hud := PanelContainer.new()
	player_hud.position = Vector2(16, 622)
	player_hud.size = Vector2(388, 80)
	player_hud.add_theme_stylebox_override("panel", _box(Color(0.025, 0.07, 0.1, 0.92), Color("32e6db"), 1, 5))
	layer.add_child(player_hud)
	var player_hud_layout := HBoxContainer.new()
	player_hud_layout.add_theme_constant_override("separation", 14)
	player_hud.add_child(player_hud_layout)
	hud_portrait = TextureRect.new()
	hud_portrait.texture = PORTRAIT
	hud_portrait.custom_minimum_size = Vector2(46, 52)
	hud_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hud_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hud_portrait.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	player_hud_layout.add_child(hud_portrait)
	player_status = _label("", 13, Color("edfaff"))
	player_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_status.autowrap_mode = TextServer.AUTOWRAP_OFF
	player_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_hud_layout.add_child(player_status)

	var quick_nav := PanelContainer.new()
	quick_nav.position = Vector2(898, 650)
	quick_nav.size = Vector2(366, 52)
	quick_nav.add_theme_stylebox_override("panel", _box(Color(0.025, 0.07, 0.1, 0.9), Color("315263"), 1, 5))
	layer.add_child(quick_nav)
	services = VBoxContainer.new()
	services.position = Vector2(1040, 24)
	services.size = Vector2(224, 140)
	layer.add_child(services)
	services.hide()
	var quick_nav_text := _label("C  角色 / 任务 / 系统    M  地图", 14, Color("c6d8df"))
	quick_nav_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quick_nav_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	quick_nav.add_child(quick_nav_text)

	character_panel = _build_character_panel()
	layer.add_child(character_panel)
	dialogue_portrait = _build_dialogue_portrait()
	layer.add_child(dialogue_portrait)
	dialogue_panel = _build_dialogue_panel()
	layer.add_child(dialogue_panel)
	map_panel = _build_map_panel()
	layer.add_child(map_panel)


func _build_battle() -> void:
	battle_screen = BATTLE_SCRIPT.new()
	add_child(battle_screen)
	battle_screen.battle_won.connect(_on_battle_won)
	battle_screen.battle_retreated.connect(_on_battle_retreated)
	battle_screen.player_defeated.connect(_on_player_defeated)


func _update_hud() -> void:
	location_label.text = "当前位置 / CURRENT LOCATION\n%s" % ("LEVEL 05 · SITE OMEGA 指挥中心" if location_id == "command" else "LEVEL B7 · 7A 收容区")
	mission_title.text = "静默回路"
	match game_state.quest_state:
		ZeroDomainGameState.QuestState.NOT_STARTED:
			mission_text.text = "与沈砚交谈，接受 B7 调查任务。"
		ZeroDomainGameState.QuestState.ACCEPTED:
			mission_text.text = "读取指挥中心安全终端。"
		ZeroDomainGameState.QuestState.TERMINAL_SCANNED:
			mission_text.text = "整备后乘电梯前往 B7。"
		ZeroDomainGameState.QuestState.IN_B7:
			mission_text.text = "找到并处理损坏的控制中继。"
		ZeroDomainGameState.QuestState.RELAY_DECIDED, ZeroDomainGameState.QuestState.BATTLE_IN_PROGRESS:
			mission_text.text = "接近并终止 Sentinel。"
		ZeroDomainGameState.QuestState.SENTINEL_DEFEATED:
			mission_text.text = "调查 Sentinel 残骸，回收认证记录。"
		ZeroDomainGameState.QuestState.RECORD_RECOVERED:
			mission_text.text = "乘电梯返回指挥中心，向沈砚汇报。"
		ZeroDomainGameState.QuestState.COMPLETE:
			if game_state.echo.reward_claimed:
				mission_title.text = "灰烬遗言"
				if not game_state.ruins.accepted:
					mission_text.text = "与沈砚交谈，确认阿斯佩拉灾后信标。"
				elif game_state.ruins.secret_recovered and not game_state.ruins.reported:
					mission_text.text = "向沈砚提交星核相位逆演。"
				elif game_state.ruins.reported:
					mission_text.text = "反制窗口已归档；最终航母战尚未开始。"
				else:
					mission_text.text = "电梯 → H1，乘游隼前往阿斯佩拉·余烬村。"
			else:
				mission_title.text = "回声之外"
				mission_text.text = "与沈砚交谈，获取外勤任务。" if not game_state.echo.accepted else ("外勤记录已回收，向沈砚汇报。" if game_state.echo.outcome != "" else "电梯 → H1 飞船舱，可出航或再次探索。")
		_:
			mission_text.text = "等待任务数据。"
	if location_id == "command" and game_state.quest_state >= ZeroDomainGameState.QuestState.IN_B7 and game_state.quest_state < ZeroDomainGameState.QuestState.RECORD_RECOVERED:
		mission_text.text = "返回 B7：" + mission_text.text
	if game_state.ruins.reported and not game_state.pirate_arc.wen_defeated:
		mission_title.text = "蚀日掠夺团"
		mission_text.text = "与沈砚交谈，开始红钻清算。" if not game_state.pirate_arc.qiu_arrested else ("C → 任务与支线：继续镜中入侵。" if not game_state.pirate_arc.mirror_cleared else "C → 任务与支线：追踪闻缄中继。")
	elif game_state.pirate_arc.wen_defeated:
		mission_title.text = "归潮新生" if game_state.pirate_arc.yue_defeated else "归潮 / 断舰之庭"
		mission_text.text = "蓝星星核已经恢复；凌霁完成首位女性统帅授衔。" if game_state.pirate_arc.yue_defeated else "C → 任务与支线：进入葬潮号主炮脊柱。"
	if is_instance_valid(commander_quest_badge):
		commander_quest_badge.visible = location_id == "command" and _commander_has_task()
	quest_log_label.text = game_state.quest_log
	player_status.text = "凌霁 · LYRA-7    CR %d\nHP %d/%d    MP %d/%d\n%s" % [game_state.credits, game_state.health, game_state.max_health, game_state.energy, game_state.max_energy, game_state.experience_text()]
	hud_portrait.texture = CHARACTER_ART.portrait(game_state)
	character_portrait.texture = CHARACTER_ART.portrait(game_state)
	character_stats.text = "LV %d   HP %d/%d   MP %d/%d\n累计经验 %d\n装备：%s · %s\n残血攻击 ×%.2f   受到伤害 ×%.2f\n探索速度 ×%.2f（不增加战斗回合）\n%s\nHP <50%% 一阶段破损；HP <25%% 二阶段破损\n%s" % [game_state.level(), game_state.health, game_state.max_health, game_state.energy, game_state.max_energy, game_state.experience, game_state.ARMOR_NAMES[game_state.equipped_armor], game_state.stage_name(), game_state.attack_multiplier(), game_state.incoming_multiplier(), game_state.speed_multiplier(), "赤线：额外 12 MP 攻击增幅 ×3，总增幅上限 ×4" if game_state.equipped_armor == "redline" else "残血增伤上限 +40%", CHARACTER_ART.art_note(game_state)]
	character_stats.text += "\nMP 模块：" + ("已装备 +40" if game_state.module_equipped else ("已持有 / 未装备" if game_state.module_owned else "未获取"))
	game_state.saved_location = location_id
	if game_state.save_progress() != OK:
		character_stats.text += "\n存档写入失败，请勿关闭游戏。"


func _commander_has_task() -> bool:
	return game_state.quest_state == ZeroDomainGameState.QuestState.NOT_STARTED \
		or game_state.quest_state == ZeroDomainGameState.QuestState.RECORD_RECOVERED \
		or (game_state.echo.outcome != "" and not game_state.echo.reward_claimed) \
		or (game_state.ruins.secret_recovered and not game_state.ruins.reported) \
		or (game_state.ruins.reported and not game_state.pirate_arc.qiu_arrested) \
		or (game_state.pirate_arc.wen_defeated and not game_state.pirate_arc.yue_defeated)


func _build_character_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.visible = false
	panel.position = Vector2(100, 40)
	panel.size = Vector2(1080, 640)
	panel.add_theme_stylebox_override("panel", _box(Color("0b1824"), Color("32e6db"), 1, 8))
	var layout := HBoxContainer.new()
	panel.add_child(layout)
	var portrait := TextureRect.new()
	character_portrait = portrait
	portrait.texture = PORTRAIT
	portrait.custom_minimum_size = Vector2(370, 580)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layout.add_child(portrait)
	var data := VBoxContainer.new()
	data.custom_minimum_size.x = 650
	layout.add_child(data)
	data.add_child(_label("CHARACTER / DOSSIER", 12, Color("64eee5")))
	data.add_child(_label("凌霁  ·  LYRA-7", 30, Color("edfaff")))
	character_tabs = TabContainer.new()
	character_tabs.custom_minimum_size = Vector2(650, 490)
	character_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	data.add_child(character_tabs)
	var equipment := _character_page("角色与装备")
	character_stats = _label("", 16, Color("c6d8df"))
	equipment.add_child(character_stats)
	_panel_button(equipment, "更换护甲（仅战斗外）", _equipment_menu)
	_panel_button(equipment, "使用背包道具", _inventory_menu)
	_panel_button(equipment, "MP 模块 · 装备 / 卸下（上限 +40）", _toggle_module)
	var tasks := _character_page("任务与支线")
	task_summary = _label("", 16, Color("d8e8ed"))
	tasks.add_child(task_summary)
	_panel_button(tasks, "罗老板 · 支线通讯", _open_luo)
	_panel_button(tasks, "蚀日掠夺团 · 红钻清算 / 镜中入侵", _open_pirate_arc)
	_panel_button(tasks, "B7 维护支路 · 查看目标", _side_objective)
	_panel_button(tasks, "训练舱 / 赤线演示（指挥中心）", _base_training)
	_panel_button(tasks, "独立物资终端（基地 / 机库）", _base_shop)
	quest_log_label = _label("", 16, Color("64eee5"))
	tasks.add_child(quest_log_label)
	var system := _character_page("保存与设置")
	system.add_child(_label("自动保存继续保留。手动保存覆盖当前存档；战斗中不可保存。\n继续游戏恢复所在区域的安全点，不是精确坐标。", 16, Color("c6d8df")))
	_panel_button(system, "立即保存进度", _manual_save)
	system_feedback = _label("", 14, Color("64eee5"))
	system.add_child(system_feedback)
	preload("res://scripts/game_settings.gd").build_controls(system)
	_panel_button(system, "保存并返回主菜单", _save_and_menu)
	data.add_child(_label("[ C / ESC ] 关闭角色菜单", 13, Color("718c98")))
	return panel


func _character_page(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	character_tabs.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)
	return body


func _refresh_tasks() -> void:
	if luo_dialogue == null:
		luo_dialogue = LUO_DIALOGUE.new(self)
	var gift := {"new": "尚未领取", "declined": "已拒绝本次赠礼", "accepted": "已收下赤线", "returned": "已退还赤线"}
	var invitation := {"none": "尚未答复", "refused": "拒绝私人邀约", "public": "仅公开场所会面", "private": "同意了解会面安排", "ended": "私人往来暂停"}
	if game_state.luo_story.stage >= 2 and not game_state.contact_ended:
		invitation[game_state.invitation] = "已选择一次短暂亲密，不承诺后续接触" if game_state.luo_story.intimacy in ["embrace", "kiss"] else "已选择保持同事距离"
	task_summary.text = "主线 · %s\n%s\n\n支线 · 罗老板\n%s；%s。\n%s\n\n支线 · B7 维护支路\n%s\n\n外勤 · 回声之外\n%s\n\n后期主线 · 灰烬遗言\n%s" % [mission_title.text, mission_text.text, gift.get(game_state.gift_status, "待核验"), "私人关系已结束" if game_state.luo_story.stage == 6 else invitation.get(game_state.invitation, "待核验"), luo_dialogue.progress_summary(), "装备与记录已回收。" if game_state.chest_claimed else ("清除警戒后按手册解开装备箱。" if game_state.route_known else "可自行调查 B7 南侧维护终端。"), "已汇报，可继续探索。" if game_state.echo.reward_claimed else ("线索 %d/3；救援%s；断桥%s。" % [game_state.echo.clues.size(), "完成" if game_state.echo.rescued else "未完成", "修复" if game_state.echo.bridge_fixed else "未修复"] if game_state.echo.accepted else "完成静默回路后找沈砚接取。"), "已归档「归潮协议」；等待航母拦截章。" if game_state.ruins.reported else ("已回收「归潮协议」，返回汇报。" if game_state.ruins.secret_recovered else ("余烬村记录 %d/3（任取2份）。" % game_state.ruins.clues.size() if game_state.ruins.accepted else "完成回声之外汇报后开启。"))]
	if game_state.ruins.reported:
		task_summary.text += "\n\n蚀日掠夺团 · %s" % ("红钻清算可接取：与沈砚交谈或点击下方入口。" if not game_state.pirate_arc.qiu_arrested else ("返回基地触发镜中入侵。" if not game_state.pirate_arc.mirror_cleared else ("闻缄中继已定位。" if not game_state.pirate_arc.wen_defeated else ("TRUE END：归潮号投入联合防卫与救援。" if game_state.pirate_arc.yue_defeated else "真实校验签名已取得；进入断舰庭挑战岳沉戈。"))))
	if game_state.mi_po.met:
		var mi_po_progress: String = "已完成，信赖 %d。" % game_state.mi_po.trust if game_state.mi_po.quest_complete else ("生活档案共振节点 %d/3，信赖 %d。" % [game_state.mi_po.resonance_nodes.size(), game_state.mi_po.trust] if game_state.mi_po.trust >= 30 and game_state.ruins.secret_recovered else "真实性校验 %d/3。" % [int(game_state.mi_po.clock_restored) + int(game_state.mi_po.pulse_verified) + int(game_state.mi_po.memorial_returned)])
		task_summary.text += "\n\n人物支线 · 为活者调弦\n" + mi_po_progress


func _open_luo() -> void:
	if luo_dialogue == null:
		luo_dialogue = LUO_DIALOGUE.new(self)
	luo_dialogue.open()


func _side_objective() -> void:
	_show_dialogue("SIDE QUEST / B7", "维护支路", "前往 B7 南侧维护终端。先解除警戒，再依次接地、供能、认证。\n" + ("你已领取装备，并备份了私人供货记录。可向罗老板核实，或暂时保留。" if game_state.chest_claimed else "奖励：复合护甲、MP 稳定器、修复包及供货记录。不影响外勤主线。"))
	_add_dialogue_choice("返回任务面板", _open_character)


func _base_training() -> void:
	if location_id != "command":
		_show_dialogue("TRAINING", "需要返回指挥中心", "训练设施不在当前区域。任务菜单不会将你远程传送回基地。")
		_add_dialogue_choice("返回角色菜单", _open_character)
		return
	_training_menu()


func _base_shop() -> void:
	if location_id not in ["command", "hangar"]:
		_show_dialogue("SUPPLY", "当前区域没有补给终端", "请返航到 H1 或回指挥中心购买补给；背包道具仍可使用。")
		_add_dialogue_choice("返回角色菜单", _open_character)
		return
	_open_shop()


func _manual_save() -> bool:
	if game_state.battle_active or mode == Mode.BATTLE:
		system_feedback.text = "战斗中不可保存。"
		return false
	game_state.persistence_enabled = true
	game_state.saved_location = location_id
	var result: Error = game_state.save_progress()
	system_feedback.text = "保存成功 · " + Time.get_time_string_from_system() if result == OK else "保存失败（%d），请勿关闭游戏。" % result
	return result == OK


func _save_and_menu() -> void:
	if _manual_save():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _build_dialogue_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.visible = false
	panel.position = Vector2(210, 252)
	panel.size = Vector2(860, 420)
	panel.add_theme_stylebox_override("panel", _box(Color("0b1824"), Color("e6a84c"), 1, 8))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 7)
	panel.add_child(body)
	dialogue_header = _label("", 12, Color("e6a84c"))
	dialogue_header.custom_minimum_size.x = 820
	body.add_child(dialogue_header)
	var speech_row := HBoxContainer.new()
	speech_row.add_theme_constant_override("separation", 12)
	body.add_child(speech_row)
	dialogue_avatar_frame = PanelContainer.new()
	dialogue_avatar_frame.custom_minimum_size = Vector2(92, 104)
	var avatar_style := _box(Color("111f2a"), Color("64eee5"), 1, 4)
	avatar_style.content_margin_left = 4
	avatar_style.content_margin_right = 4
	avatar_style.content_margin_top = 4
	avatar_style.content_margin_bottom = 4
	dialogue_avatar_frame.add_theme_stylebox_override("panel", avatar_style)
	speech_row.add_child(dialogue_avatar_frame)
	dialogue_avatar = TextureRect.new()
	dialogue_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dialogue_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	dialogue_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_avatar_frame.add_child(dialogue_avatar)
	var speech_text := VBoxContainer.new()
	speech_text.custom_minimum_size.x = 700
	speech_text.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	speech_text.add_theme_constant_override("separation", 4)
	speech_row.add_child(speech_text)
	dialogue_name = _label("", 23, Color("fff0cf"))
	dialogue_name.custom_minimum_size.x = 700
	speech_text.add_child(dialogue_name)
	dialogue_text_scroll = ScrollContainer.new()
	dialogue_text_scroll.custom_minimum_size = Vector2(700, 136)
	dialogue_text_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dialogue_text_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	speech_text.add_child(dialogue_text_scroll)
	dialogue_line = _label("", 16, Color("d8e8ed"))
	dialogue_line.custom_minimum_size = Vector2(676, 58)
	dialogue_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_text_scroll.add_child(dialogue_line)
	dialogue_choices = VBoxContainer.new()
	dialogue_choices.add_theme_constant_override("separation", 5)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 170
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	dialogue_choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(dialogue_choices)
	var close_hint := _label("[ ESC ] 结束对话", 13, Color("718c98"))
	close_hint.custom_minimum_size.x = 820
	body.add_child(close_hint)
	return panel


func _build_dialogue_portrait() -> TextureRect:
	var portrait := TextureRect.new()
	portrait.visible = false
	portrait.position = Vector2(8, 212)
	portrait.size = Vector2(250, 390)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return portrait


func _show_dialogue(header: String, speaker: String, line: String) -> void:
	_clear_luo_story_picture()
	for child: Node in dialogue_choices.get_children():
		dialogue_choices.remove_child(child)
		child.queue_free()
	dialogue_header.text = header
	dialogue_name.text = speaker
	dialogue_line.text = line
	dialogue_text_scroll.scroll_vertical = 0
	_update_dialogue_art(speaker)
	_open_modal(dialogue_panel)


func _update_dialogue_art(speaker: String) -> void:
	var portrait: Texture2D = _portrait_for_speaker(speaker)
	var has_portrait: bool = portrait != null
	dialogue_avatar.texture = _avatar_for_speaker(speaker)
	dialogue_portrait.texture = portrait
	dialogue_avatar_frame.visible = has_portrait
	dialogue_portrait.visible = has_portrait


func _portrait_for_speaker(speaker: String) -> Texture2D:
	if speaker.contains("弥珀"):
		return MI_PO_ART
	if speaker.contains("闻缄"):
		return WEN_JIAN_ART
	if speaker.contains("罗茂") and ResourceLoader.exists("res://assets/npcs/luo-mao-rpg-v1.png"):
		return load("res://assets/npcs/luo-mao-rpg-v1.png") as Texture2D
	if speaker.contains("沈砚"):
		return COMMANDER_ART
	if speaker.contains("凌霁") or speaker.contains("LYRA-7"):
		return CHARACTER_ART.portrait(game_state)
	return null


func _avatar_for_speaker(speaker: String) -> Texture2D:
	if speaker.contains("弥珀"):
		var mi_po_avatar := AtlasTexture.new()
		mi_po_avatar.atlas = MI_PO_PORTRAITS
		var stage: int = 2 if game_state.mi_po.trust >= 80 else (1 if game_state.mi_po.trust >= 30 else 0)
		mi_po_avatar.region = Rect2(stage * 724, 0, 724, 724)
		return mi_po_avatar
	if speaker.contains("闻缄"):
		return WEN_JIAN_ART
	if speaker.contains("罗茂"):
		var luo_avatar := AtlasTexture.new()
		luo_avatar.atlas = _portrait_for_speaker(speaker)
		luo_avatar.region = Rect2(220, 40, 600, 600)
		return luo_avatar if luo_avatar.atlas != null else null
	var avatar := AtlasTexture.new()
	if speaker.contains("沈砚"):
		avatar.atlas = COMMANDER_ART
		avatar.region = Rect2(320, 80, 620, 620)
		return avatar
	if speaker.contains("凌霁") or speaker.contains("LYRA-7"):
		avatar.atlas = PORTRAIT
		avatar.region = Rect2(220, 80, 600, 600)
		return avatar
	return null


func _clear_luo_story_picture() -> void:
	if is_instance_valid(luo_story_picture):
		luo_story_picture.hide()
		luo_story_picture.queue_free()
		luo_story_picture = null


func _show_luo_story_picture(chapter: int, intimacy: String) -> void:
	var picture_script: Script = load("res://scripts/luo_story_scene.gd") as Script
	luo_story_picture = picture_script.new() as Control
	dialogue_panel.get_parent().add_child(luo_story_picture)
	luo_story_picture.call("stage_picture", chapter, intimacy)
	dialogue_portrait.hide()


func _show_story_picture(texture: Texture2D) -> void:
	_clear_luo_story_picture()
	var picture := TextureRect.new()
	picture.position = Vector2(210, 12)
	picture.size = Vector2(860, 228)
	picture.texture = texture
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_panel.get_parent().add_child(picture)
	luo_story_picture = picture
	dialogue_portrait.hide()


func _add_dialogue_choice(title: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 30
	button.pressed.connect(callback)
	dialogue_choices.add_child(button)


func _expedition_briefing() -> void:
	if game_state.echo.outcome != "" and not game_state.echo.reward_claimed:
		_show_dialogue("回声之外 / DEBRIEF", "沈砚", "你在基地外找到了另一段认证链路？先提交隔离记录。无论保留还是关闭信标，基础任务奖励相同。")
		_add_dialogue_choice("提交外勤记录 · 300 CR / 300 EXP", _report_expedition)
	elif not game_state.echo.accepted:
		_show_dialogue("外勤任务 / ECHO-9", "沈砚", "基地外一个被删去的冰原坐标，刚刚回应了你的识别码。这可能是核心区信号的另一段链路。\n乘‘游隼’去灰潮盆地，取得两份定位线索，调查观测站。你可以绕开战斗，也可以随时返航。")
		_add_dialogue_choice("接受外勤任务，开放 H1 飞船舱", _accept_expedition)
		_add_dialogue_choice("稍后出发", _close_modals)
	else:
		_show_dialogue("外勤任务 / ECHO-9", "沈砚", "H1 飞船舱已开放。乘东侧电梯下去，再从游隼舷梯登舰。高地、货船和栈道可自由调查，任意两份线索即可核验观测站。")
		_add_dialogue_choice("结束简报", _close_modals)


func _ruins_briefing() -> void:
	if game_state.ruins.reported:
		if not game_state.pirate_arc.qiu_arrested:
			_show_dialogue("后期主线 / RED DIAMOND", "沈砚", "归潮协议已经给出登舰窗口。我们截获了裘盛万藏库的邀请凭证；这不是普通战斗，而是一场所有权清算。")
			_add_dialogue_choice("开始「红钻清算」", _open_pirate_arc)
		else:
			_show_dialogue("灰烬遗言 / ARCHIVED", "沈砚", "「归潮协议」已转入蓝星外围防御模拟。裘盛已被拘捕；继续从任务面板追踪闻缄留下的镜面载波。")
		return
	if not game_state.ruins.accepted:
		_show_dialogue("后期主线 / 阿斯佩拉", "沈砚", "阿斯佩拉文明的救难信标刚刚停止。蚀日掠夺团已经离开，余烬村周围只剩废墟和极少数生命反应。\n他们的星图指向蓝星。我们打不穿那艘航母，但废墟中也许留有被攻击者曾经打断抽取锁的方法。")
		_add_dialogue_choice("接受灾后勘探，寻找拦截条件", _accept_ruins_mission)
		_add_dialogue_choice("暂缓出发", _close_modals)
	else:
		_show_dialogue("灰烬遗言 / 余烬村", "沈砚", "去 H1 选择阿斯佩拉航线。从钻击坑、纪念塔和观测台中任意调查两处，然后进入星核祭库。第三份记录可提供解谜校验，但不是必需。\n任务只是找到拦截条件，不是提前与三名首领或航母正面交战。")


func _accept_ruins_mission() -> void:
	game_state.accept_ruins_mission()
	_update_hud()
	_ruins_briefing()


func _report_ruins_mission() -> void:
	if not game_state.claim_ruins_reward():
		return
	_show_dialogue("灰烬遗言 / MISSION COMPLETE", "沈砚", "凌霁将隔离芯片放入读取槽。余烬村留下的「归潮协议」，可以让航母的星核抽取锁短暂失效。\n沈砚：“这给了我们一个窗口，不是一场自动胜利。下一步是把你送到它的抽取阵列附近。”\n\n获得 450 CR / 500 EXP。蓝星拦截条件已归档；最终航母战尚未实装。")
	_update_hud()


func _open_pirate_arc() -> void:
	if location_id != "command":
		_show_dialogue("蚀日掠夺团 / BASE ONLY", "任务终端", "红钻清算与卧室镜中入侵只能在指挥中心启动。请先返回基地。")
	elif not game_state.ruins.reported:
		_show_dialogue("蚀日掠夺团 / LOCKED", "任务终端", "完成并汇报「灰烬遗言」后，才能进入红钻清算。")
	elif not game_state.pirate_arc.qiu_arrested:
		_show_gamble_round()
	elif not game_state.pirate_arc.returned_base:
		_show_dialogue("红钻清算 / ARREST", "执法记录", "裘盛按下桌底逃生开关，防爆门却被托管系统锁死。冻结令已经送达，执法人员将他带离万藏库。")
		_add_dialogue_choice("结束行动并返回基地", _return_after_qiu)
	elif not game_state.pirate_arc.mirror_cleared:
		_show_mirror_anchor()
	elif game_state.pirate_arc.boarding_stage == 0:
		_show_dialogue("镜中入侵 / TARGET LOCKED", "凌霁", "幻境已经退去，手环锁定了闻缄的蜃心中继舰。静默甲板仍有一组警戒兵。")
		_add_dialogue_choice("乘游隼突入 · 清理静默甲板", _start_pirate_battle.bind("pirate_guard_1"))
	elif game_state.pirate_arc.boarding_stage == 1:
		_show_dialogue("蜃心中继舰 / ECHO DECK", "凌霁", "甲板干扰器已关闭。回声舱的幻影守卫挡在控魂中枢之前。")
		_add_dialogue_choice("校验真实目标 · 清理回声舱", _start_pirate_battle.bind("pirate_guard_2"))
	elif not game_state.pirate_arc.wen_defeated:
		_show_dialogue("镜中入侵 / TARGET LOCKED", "凌霁", "幻境已经退去，手环锁定了闻缄的控魂中继。千声室的全连接会让双方读取指令签名；战败将进入不可续接的 BE，必须读取入场前存档。")
		_add_dialogue_choice("建立安全存档并进入千声室", _start_wen_battle)
		_add_dialogue_choice("返回整备", _close_modals)
	elif not game_state.pirate_arc.yue_defeated:
		_show_dialogue("归潮 / FINAL OPERATION", "沈砚", "闻缄的真实校验签名已经打开主炮脊柱航路。岳沉戈仍在断舰庭维持星核抽取锚。进入前将完成一次免费整备并建立安全存档。")
		_add_dialogue_choice("进入葬潮号 · 断舰庭", _enter_finale)
	else:
		_show_dialogue("归潮 / TRUE END", "任务终端", "岳沉戈已经战败，蓝星星核恢复稳定。归潮号现由多文明联合防卫与救援体系监管。")


func _show_gamble_round(feedback: String = "") -> void:
	var round_index: int = int(game_state.pirate_arc.gamble_round)
	var rules: Array[String] = ["首局为庄家暗仓：无论骰点都会真实败北。", "第二局：选择 ↑ 追溯上游，并掷出3—6点。", "第三局：选择 ← 连接左侧证物，并掷出1—4点。"]
	_show_dialogue("红钻清算 / ROUND %d" % (round_index + 1), "赌桌托管程序", (feedback + "\n" if not feedback.is_empty() else "") + rules[round_index])
	for direction: String in PIRATE_RULES.DIRECTIONS:
		_add_dialogue_choice({"up": "↑ 上", "right": "→ 右", "down": "↓ 下", "left": "← 左"}[direction] + " · 掷骰", _resolve_gamble_input.bind(direction, 0))


func _resolve_gamble_input(direction: String, forced_die: int = 0) -> void:
	var die: int = forced_die if forced_die in range(1, 7) else randi_range(1, 6)
	var result: String = PIRATE_RULES.resolve_gamble_round(game_state.pirate_arc, direction, die)
	var text: String = {"lost_first": "首局败北，凌霁交出钻石与披肩。", "won_second": "溯源成功，凌霁取得强制披露权。", "qiu_arrested": "追偿链闭合，资金冻结；执法队进场拘捕裘盛。", "retry": "方向或骰点未满足规则，本局未落槌。"}.get(result, "输入无效。")
	if result == "qiu_arrested":
		_show_dialogue("红钻清算 / COMPLETE", "凌霁", "骰点 %d。%s\n裘盛扑向桌底的逃生开关，但托管程序已经接管防爆门。" % [die, text])
		_add_dialogue_choice("查看执法记录", _open_pirate_arc)
		_update_hud()
	else:
		_show_gamble_round("骰点 %d · %s" % [die, text])


func _return_after_qiu() -> void:
	if game_state.return_after_qiu_arrest():
		game_state.saved_location = "command"
	_show_dialogue("基地私人舱 / NIGHT", "凌霁", "行动结束。当晚，凌霁卸下任务装备完成洗漱；镜面的雾气却开始逆向凝结。")
	_add_dialogue_choice("查看镜面", _show_mirror_anchor)


func _show_mirror_anchor(feedback: String = "") -> void:
	var step: int = int(game_state.pirate_arc.mirror_anchor_step)
	var lines: Array[String] = ["闻缄的虚影比凌霁的动作慢了半拍。‘下一次，你连自己在害怕什么都分不清。’澄明手环仍记录着真实脉搏。", "已经离世的朋友与家人出现在身后，声音几乎与记忆相同，却要求她放弃仍活着的人。", "幻境把窗外星图左右翻转。凌霁承认自己的思念，仍选择追踪活人的求救信号。"]
	if game_state.mi_po.trust >= 30 and step == 1:
		lines[step] = "弥珀：‘这段回忆的频谱太完美了。他复制了声音，没复制人的迟疑。’\n" + lines[step]
	_show_dialogue("当夜 / 镜中入侵", "闻缄 / 引魂师", (feedback + "\n" if not feedback.is_empty() else "") + lines[step])
	_add_dialogue_choice("手环脉搏", _choose_mirror_anchor.bind("bracelet"))
	_add_dialogue_choice("辨认违背故人本心的话", _choose_mirror_anchor.bind("memory"))
	_add_dialogue_choice("校验窗外星图", _choose_mirror_anchor.bind("stars"))
	_show_story_picture(WEN_JIAN_MIRROR_CG)


func _choose_mirror_anchor(anchor: String) -> void:
	var before: int = int(game_state.pirate_arc.mirror_anchor_step)
	var accepted: bool = game_state.resolve_mirror_anchor(anchor)
	if game_state.pirate_arc.mirror_cleared:
		_open_pirate_arc()
	else:
		_show_mirror_anchor("现实锚点确认。" if accepted and int(game_state.pirate_arc.mirror_anchor_step) > before else "幻象侵入，锚点顺序重置。")


func _start_wen_battle() -> void:
	if not game_state.persistence_enabled or game_state.save_progress() != OK:
		_show_dialogue("千声室 / CHECKPOINT ERROR", "系统", "无法建立入场前安全存档。为避免战败后无法读取，本次不会进入首领战。")
		_add_dialogue_choice("返回整备", _close_modals)
		return
	_start_pirate_battle("wen_jian")


func _start_pirate_battle(encounter: String) -> void:
	_close_modals()
	mode = Mode.BATTLE
	player.call("set_controls_enabled", false)
	battle_screen.setup(game_state, encounter)


func _accept_expedition() -> void:
	game_state.accept_expedition()
	_update_hud()
	_expedition_briefing()


func _report_expedition() -> void:
	if not game_state.claim_echo_reward():
		return
	_show_dialogue("回声之外 / MISSION COMPLETE", "沈砚", "“三年前，基地批准过你的返航？”沈砚沉默片刻，将记录从网络隔离。\n“这不能证明你去过那里。但有人希望我们这样认为。”\n获得 300 CR / 300 EXP。你仍可乘船返回盆地，完成尚未处理的探索。")
	_update_hud()


func _enter_hangar() -> void:
	if not game_state.echo.accepted or game_state.quest_state != ZeroDomainGameState.QuestState.COMPLETE:
		return
	game_state.saved_location = "hangar"
	game_state.save_progress()
	get_tree().change_scene_to_file("res://scenes/expedition.tscn")


func _enter_mech_bay() -> void:
	if game_state.quest_state < ZeroDomainGameState.QuestState.TERMINAL_SCANNED:
		return
	game_state.saved_location = "command"
	game_state.save_progress()
	get_tree().change_scene_to_file("res://scenes/mech_bay.tscn")


func _panel_button(parent: VBoxContainer, title: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 34
	button.pressed.connect(callback)
	parent.add_child(button)


func _open_character() -> void:
	_update_hud()
	_refresh_tasks()
	_open_modal(character_panel)


func _equipment_menu() -> void:
	_show_dialogue("EQUIPMENT / ARMOR", "战斗外换装", "制式重甲始终保留。赤线受到伤害 ×2；复合护甲受到伤害 ×0.9、移动 ×0.95。换装不会回复 HP/MP。")
	for armor: String in game_state.owned_armors:
		_add_dialogue_choice(game_state.ARMOR_NAMES[armor] + (" · 当前装备" if game_state.equipped_armor == armor else ""), _equip.bind(armor))
	_add_dialogue_choice("返回人物面板", _open_character)


func _equip(armor: String) -> void:
	game_state.equip_armor(armor)
	_open_character()


func _toggle_module() -> void:
	if game_state.toggle_module():
		_open_character()
	else:
		_show_dialogue("EQUIPMENT / MODULE", "尚未持有稳定器", "可在 B7 维护支路的解谜装备箱获取。装备仅提高上限，不会补满 MP。")
		_add_dialogue_choice("返回人物面板", _open_character)


func _inventory_menu(feedback: String = "") -> void:
	_show_dialogue("INVENTORY / ITEMS", "道具背包", feedback + "\n每种最多 9 个；满血或满 MP 时不会消耗。战斗中使用道具会占用一个回合。")
	for item: String in game_state.ITEM_NAMES:
		_add_dialogue_choice("%s  ×%d" % [game_state.ITEM_NAMES[item], game_state.inventory[item]], _use_item.bind(item))
	_add_dialogue_choice("返回人物面板", _open_character)


func _use_item(item: String) -> void:
	var used := game_state.use_item(item)
	_update_hud()
	_inventory_menu("已使用：" + game_state.ITEM_NAMES[item] if used else "未使用：道具不足，或相应数值已满。")


func _open_shop(feedback: String = "") -> void:
	_show_dialogue("BASE SUPPLY / INDEPENDENT", "基地独立物资终端", "%s\n信用点 %d CR。这里的标准电池同样适配赤线，不需要接受罗老板的私人要求。" % [feedback, game_state.credits])
	_add_dialogue_choice("购买医疗凝胶 · 50 CR（持有 %d）" % game_state.inventory.med_gel, _buy_item.bind("med_gel"))
	_add_dialogue_choice("购买标准电池 · 60 CR（持有 %d）" % game_state.inventory.battery, _buy_item.bind("battery"))
	_add_dialogue_choice("离开终端", _close_modals)


func _buy_item(item: String) -> void:
	var bought := game_state.buy_item(item)
	_update_hud()
	_open_shop("购买成功。" if bought else "未扣款：信用点不足或该道具已达 9 个。")


func _training_menu() -> void:
	_show_dialogue("TRAINING / SIMULATION", "训练舱", "普通演练：150 HP，胜利 +90 EXP / 20 CR，可以重复练级，消耗正常保留。\n赤线演示：90 HP，无奖励；结束恢复入场 HP、MP 和道具。")
	_add_dialogue_choice("普通演练 · 开始战斗", _start_optional_battle.bind("practice"))
	_add_dialogue_choice("赤线演示 · 需先穿戴赤线", _start_optional_battle.bind("demo"))
	_add_dialogue_choice("离开", _close_modals)


func _start_optional_battle(encounter: String) -> void:
	if mode == Mode.BATTLE or encounter not in ["practice", "demo", "side"]:
		return
	if encounter in ["practice", "demo"] and location_id != "command":
		_base_training()
		return
	if encounter == "demo" and game_state.equipped_armor != "redline":
		_show_dialogue("TRAINING / REDLINE", "请先穿戴赤线", "接受礼物后，按 C → 更换护甲。模拟演示不会替你换装。")
		_add_dialogue_choice("打开人物装备", _open_character)
		return
	_close_modals()
	mode = Mode.BATTLE
	services.hide()
	player.call("set_controls_enabled", false)
	battle_screen.setup(game_state, encounter)


func _interact_side_terminal() -> void:
	game_state.route_known = true
	if game_state.chest_claimed:
		_show_dialogue("B7 / MAINTENANCE", "装备箱已回收", "复合护甲、稳定器、修复包与私人供货记录已收好。记录可用于向罗老板核实其非公开关系。")
	elif not game_state.side_patrol_defeated:
		_show_dialogue("B7 / MAINTENANCE", "警戒尚未解除", "终端检测到额外的 150 HP 巡逻机。这条支路不是安全捷径。\n可先撤回，不影响静默回路主线；击败警戒后才能操作装备箱。")
		_add_dialogue_choice("清除支路巡逻机", _start_optional_battle.bind("side"))
		_add_dialogue_choice("暂时离开", _close_modals)
	else:
		puzzle_step = 0
		_puzzle_menu()


func _puzzle_menu(feedback: String = "") -> void:
	_show_dialogue("B7 / EQUIPMENT CACHE", "三路安全锁 · %d/3" % puzzle_step, "%s\n维修手册：先消除静电，再接通电源，最后核验身份。失败只重置顺序，不扣资源。" % feedback)
	for key: String in ["认证", "接地", "供能"]:
		_add_dialogue_choice(key, _puzzle_input.bind(key))
	_add_dialogue_choice("稍后再来", _close_modals)


func _puzzle_input(key: String) -> void:
	if game_state.chest_claimed or not game_state.side_patrol_defeated:
		return
	if key != ["接地", "供能", "认证"][puzzle_step]:
		puzzle_step = 0
		_puzzle_menu("顺序错误，安全锁已复位。")
		return
	puzzle_step += 1
	if puzzle_step < 3:
		_puzzle_menu("接口响应正常。")
	elif game_state.claim_chest():
		_show_dialogue("B7 / EQUIPMENT CACHE", "装备箱开启", "获得复合护甲、稳定器模块、修复包 ×1。\n附带记录显示，这批试制件没有经过公库审批；担保人是罗茂，去向栏只写着‘确保凌霁安全返航’。\n已备份私人供货记录；装备不会自动穿戴。")
		_update_hud()
	else:
		puzzle_step = 0
		_puzzle_menu("修复包已达上限，请先腾出一个位置。箱内奖励尚未领取。")


func _build_map_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.visible = false
	panel.position = Vector2(300, 120)
	panel.size = Vector2(680, 440)
	panel.add_theme_stylebox_override("panel", _box(Color("0b1824"), Color("32e6db"), 1, 8))
	var body := VBoxContainer.new()
	panel.add_child(body)
	body.add_child(_label("SITE OMEGA / NAVIGATION", 12, Color("64eee5")))
	body.add_child(_label("基地地图", 30, Color("edfaff")))
	body.add_child(_label("● LEVEL 05  指挥中心       可进入\n● LEVEL B7  7A 收容区      清除任务\n○ Q5        凌霁私人舱     后续迁移\n○ B2        审讯区         后续迁移\n× LEVEL 06  核心区         访问受限", 20, Color("c6d8df")))
	body.add_child(_label("[ M / ESC ] 关闭地图", 13, Color("718c98")))
	return panel


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _box(color: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
