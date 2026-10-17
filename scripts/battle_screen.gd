class_name ZeroDomainBattleScreen
extends CanvasLayer

signal battle_won
signal battle_retreated
signal player_defeated

enum Phase { HIDDEN, PLAYER_TURN, ENEMY_TURN, RESOLVING }

const PLAYER_IDLE := preload("res://assets/characters/lyra-portrait-2d-v1.png")
const CHARACTER_ART := preload("res://scripts/character_art.gd")
const SENTINEL := preload("res://assets/enemies/sentinel-2d-v1.png")
const WEN_JIAN := preload("res://assets/enemies/wen-jian-combat-v1.png")
const YUE_CHENGE := preload("res://assets/enemies/yue-chenge-normal-v1.png")
const YUE_CHENGE_BEAST := preload("res://assets/enemies/yue-chenge-beast-v1.png")
const BATTLE_BACKGROUND := preload("res://assets/environments/b7-battle-2d-v1.png")
const WEN_JIAN_BACKGROUND := preload("res://assets/environments/wen-jian-core-battle-v1.png")
const YUE_BACKGROUND := preload("res://assets/environments/yue-final-map-v1.png")
const PIRATE_RULES := preload("res://scripts/pirate_arc_rules.gd")
const VOYAGE_ENCOUNTERS := preload("res://scripts/voyage_encounters.gd")

const ENEMY_MAX_HEALTH: int = 220
const SKILL_COST: int = 60

var phase: Phase = Phase.HIDDEN
var game_state: ZeroDomainGameState
var enemy_health: int = ENEMY_MAX_HEALTH
var enemy_max_health: int = ENEMY_MAX_HEALTH
var enemy_damage_multiplier: float = 1.0
var enemy_turn_count: int = 0
var guarding: bool = false
var counter_ready: bool = false
var victory_resolved: bool = false
var encounter_id: String = "main"
var demo_health: int
var demo_energy: int
var demo_inventory: Dictionary
var barrier_ready: bool = false
var pending_action: String = ""
var control_chain: int = 0
var control_immunity_turns: int = 0
var player_turns_skipped: int = 0
var mind_control_warning: bool = false
var yue_second_form: bool = false
var boost_confirmation: ConfirmationDialog
var choice_panel: PanelContainer
var choice_list: VBoxContainer
var result_panel: PanelContainer
var result_title: Label
var result_detail: Label
var total_damage_dealt: int = 0
var voyage_config: Dictionary = {}
var last_player_action: String = ""
var repeated_player_action: bool = false
var bound_turns: int = 0
var bind_immunity_turns: int = 0
var support_heals: int = 0
var enemy_guard_ratio: float = 1.0
var mi_po_early_warning_pending: bool = false
var mi_po_barrier_available: bool = false
var mi_po_barrier_triggered: bool = false
var mi_po_yue_support_available: bool = false

var root: Control
var environment_art: TextureRect
var player_art: TextureRect
var enemy_art: TextureRect
var enemy_health_bar: ProgressBar
var player_health_bar: ProgressBar
var player_mp_bar: ProgressBar
var enemy_health_label: Label
var enemy_name_label: Label
var heading_label: Label
var player_status_label: Label
var combat_log: Label
var action_buttons: Array[Button] = []


func _ready() -> void:
	layer = 50
	_build_interface()
	root.hide()


func setup(state: ZeroDomainGameState, encounter: String = "main") -> void:
	environment_art.texture = BATTLE_BACKGROUND
	enemy_art.texture = SENTINEL
	game_state = state
	game_state.battle_active = true
	encounter_id = encounter
	voyage_config = VOYAGE_ENCOUNTERS.config(encounter)
	demo_health = state.health
	demo_energy = state.energy
	demo_inventory = state.inventory.duplicate()
	enemy_max_health = 170 if game_state.relay_choice == ZeroDomainGameState.RelayChoice.CUT_POWER else ENEMY_MAX_HEALTH
	enemy_damage_multiplier = 0.9 if game_state.relay_choice == ZeroDomainGameState.RelayChoice.CUT_POWER else 1.0
	if encounter != "main":
		enemy_max_health = 90 if encounter == "demo" else 150
		enemy_damage_multiplier = 0.5 if encounter == "demo" else 0.8
	if encounter == "echo_guard":
		enemy_max_health = 220
		enemy_damage_multiplier = 1.0
	if not voyage_config.is_empty():
		enemy_max_health = int(voyage_config.hp)
		enemy_damage_multiplier = 1.0
		enemy_art.texture = VOYAGE_ENCOUNTERS.texture(encounter)
	if encounter == "wen_jian":
		enemy_max_health = 360
		enemy_damage_multiplier = 1.15
		environment_art.texture = WEN_JIAN_BACKGROUND
		enemy_art.texture = WEN_JIAN
	elif encounter == "yue_chenge":
		enemy_max_health = 620
		enemy_damage_multiplier = 1.4
		environment_art.texture = YUE_BACKGROUND
		enemy_art.texture = YUE_CHENGE
	elif encounter == "pirate_guard_1":
		enemy_max_health = 160
		enemy_damage_multiplier = 0.85
	elif encounter == "pirate_guard_2":
		enemy_max_health = 190
		enemy_damage_multiplier = 0.95
	enemy_health = enemy_max_health
	enemy_turn_count = 0
	guarding = false
	barrier_ready = false
	pending_action = ""
	control_chain = 0
	control_immunity_turns = 0
	player_turns_skipped = 0
	mind_control_warning = false
	yue_second_form = false
	total_damage_dealt = 0
	last_player_action = ""
	repeated_player_action = false
	bound_turns = 0
	bind_immunity_turns = 0
	support_heals = 0
	enemy_guard_ratio = 1.0
	mi_po_early_warning_pending = encounter == "wen_jian" and int(game_state.mi_po.trust) >= 30
	mi_po_barrier_available = encounter == "wen_jian" and int(game_state.mi_po.trust) >= 80
	mi_po_barrier_triggered = false
	mi_po_yue_support_available = encounter == "yue_chenge" and int(game_state.mi_po.trust) >= 80
	if game_state.mi_po.module_claimed and int(game_state.mi_po.trust) < 80:
		game_state.energy = mini(game_state.max_energy, game_state.energy + 30)
	boost_confirmation.hide()
	choice_panel.hide()
	result_panel.hide()
	counter_ready = false
	victory_resolved = false
	phase = Phase.PLAYER_TURN
	player_art.texture = PLAYER_IDLE
	player_art.position = Vector2(782, 22)
	player_art.modulate = Color.WHITE
	combat_log.text = "SENTINEL 锁定了你。它每三次行动会发动蓄力重击。"
	if encounter == "demo":
		combat_log.text = "90 HP 模拟靶：赤线增幅可一击击倒。结束后恢复入场 HP/MP/道具，无奖励。"
	elif encounter != "main":
		combat_log.text = "巡逻机每第三回合重击。训练胜利 +90 EXP / 20 CR；警戒战不奖励经验。"
	if encounter.begins_with("echo_"):
		combat_log.text = "每第三次行动有重击。可以撤离，或寻找非战斗路线；失败会送回着陆点。"
	elif encounter == "wen_jian":
		combat_log.text = "闻缄分三阶段：镜语试探→亡者回声→反噬核心，控魂预警逐步加快。看到紫色裂纹后用【战术防御】锚定现实；最多连续失控两回合。"
		if int(game_state.mi_po.trust) >= 30:
			combat_log.text += "\n弥珀的相位辨识频道已上线：首次控魂预警将提前一回合。"
	elif encounter == "yue_chenge":
		combat_log.text = "岳沉戈第一形态已连接主炮回冲系统。观察蓄能提示，以战术防御承受重击并打开反击窗口。"
	elif not voyage_config.is_empty():
		combat_log.text = "%s出现。%s\n战利品：%s；胜利奖励 %d EXP / %d CR。" % [voyage_config.name, voyage_config.skill, voyage_config.drop, voyage_config.exp, voyage_config.credits]
	root.show()
	_set_actions_enabled(true)
	_update_display()


func _unhandled_input(event: InputEvent) -> void:
	if not root.visible or phase != Phase.PLAYER_TURN or boost_confirmation.visible or choice_panel.visible:
		return
	if event.is_action_pressed("battle_attack"):
		_perform_action("attack")
	elif event.is_action_pressed("battle_skill"):
		_perform_action("skill")
	elif event.is_action_pressed("battle_guard"):
		_perform_action("guard")
	elif event.is_action_pressed("battle_retreat"):
		_perform_action("retreat")


func _perform_action(action: String, unboosted: bool = false) -> void:
	if phase != Phase.PLAYER_TURN or game_state.health <= 0 or boost_confirmation.visible or choice_panel.visible:
		return
	if action == "retreat":
		phase = Phase.RESOLVING
		_end_encounter()
		root.hide()
		battle_retreated.emit()
		return
	if action in ["items", "skills"]:
		_open_choices(action)
		return
	if action not in ["attack", "skill", "pierce", "barrier", "guard"] and not action.begins_with("item:"):
		return
	if (action == "pierce" and game_state.level() < 4) or (action == "barrier" and game_state.level() < 5):
		return
	var attacking := action in ["attack", "skill", "pierce"]
	var cost := 60 if action == "skill" else (80 if action == "pierce" else (45 if action == "barrier" else 0))
	if game_state.energy < cost:
		combat_log.text = "MP 不足：此技能需要 %d MP。本次没有消耗回合。" % cost
		_update_display()
		return
	var boosted := attacking and game_state.equipped_armor == "redline" and not unboosted
	if boosted and game_state.energy < cost + 12:
		_update_display()
		pending_action = action
		boost_confirmation.dialog_text = "技能基础消耗 %d MP，赤线额外需要 12 MP（合计 %d）。\n目前只有 %d MP。要取消，还是只执行不增幅攻击？\n赤线的受到伤害 ×2 仍然生效。" % [cost, cost + 12, game_state.energy]
		boost_confirmation.popup_centered(Vector2i(540, 180))
		return
	if action == "item:anti_adhesion_spray":
		if int(game_state.voyage.sprays) <= 0:
			combat_log.text = "抗黏附喷剂已用完。"
			return
		game_state.voyage.sprays -= 1
		bound_turns = 0
		bind_immunity_turns = 3
	elif action.begins_with("item:") and not game_state.use_item(action.trim_prefix("item:")):
		combat_log.text = "道具不足或当前已满，未消耗道具与回合。"
		return
	game_state.spend_energy(cost + (12 if boosted else 0))
	if boosted:
		game_state.redline_used = true
	var anchored_guard: bool = encounter_id == "wen_jian" and action == "guard" and mind_control_warning
	if anchored_guard:
		_anchor_mind_control()

	phase = Phase.ENEMY_TURN
	_set_actions_enabled(false)
	if control_immunity_turns > 0:
		control_immunity_turns -= 1
	var damage: int = 0
	var action_name: String = ""
	if action == "attack":
		damage = randi_range(34, 42) + maxi(0, game_state.level() - 3) * 3
		action_name = "脉冲斩击"
	elif action == "skill":
		damage = randi_range(68, 80) + maxi(0, game_state.level() - 3) * 6
		action_name = "过载突袭"
	elif action == "pierce":
		damage = randi_range(90, 105)
		action_name = "电磁穿刺"
	elif action == "barrier":
		barrier_ready = true
		action_name = "应急屏障：下次受到伤害 ×0.25，不触发反击"
	elif action.begins_with("item:"):
		action_name = "已使用 " + game_state.ITEM_NAMES[action.trim_prefix("item:")]
	elif action == "guard":
		guarding = true
		action_name = "现实锚定：控魂被反制，反击窗口开启" if anchored_guard else "战术防御"

	if damage > 0:
		damage = floori(damage * game_state.attack_multiplier(boosted, counter_ready))
		if bound_turns > 0:
			damage = floori(damage * 0.75)
			bound_turns = 0
			action_name += " · 挣脱缠根"
		if encounter_id == "voyage_faceless_observer" and action == last_player_action:
			damage = floori(damage * 0.5)
			action_name += " · 被观测反射"
		damage = floori(damage * enemy_guard_ratio)
		enemy_guard_ratio = 1.0
		if counter_ready:
			counter_ready = false
			action_name += " · 反击"
		if boosted:
			action_name += " · 赤线增幅"
		enemy_health = maxi(0, enemy_health - damage)
		total_damage_dealt += damage
		var strike := create_tween()
		strike.tween_property(player_art, "position:x", 766.0, 0.10)
		strike.tween_property(player_art, "position:x", 782.0, 0.18)
		combat_log.text = "%s命中，造成 %d 点伤害。" % [action_name, damage]
	else:
		combat_log.text = "进入战术防御姿态：本回合减伤 65%。" if action == "guard" else action_name
	repeated_player_action = action == last_player_action and action in ["attack", "skill", "pierce", "guard"]
	last_player_action = action

	_update_display()
	if enemy_health == 0:
		_finish_victory()
		return
	await get_tree().create_timer(0.42).timeout
	_enemy_turn()


func _enemy_turn() -> void:
	if phase != Phase.ENEMY_TURN or enemy_health == 0:
		return
	enemy_turn_count += 1
	var heavy_attack: bool = enemy_turn_count % (2 if encounter_id == "yue_chenge" and yue_second_form else 3) == 0
	var rage: bool = enemy_health < enemy_max_health / 2
	var raw_damage: float = randi_range(int(voyage_config.damage.x), int(voyage_config.damage.y)) if not voyage_config.is_empty() else randi_range(38, 48)
	var detail: String = "闻缄 · 侵蚀脉冲" if encounter_id == "wen_jian" else ("岳沉戈 · 裂舰扑杀" if encounter_id == "yue_chenge" and yue_second_form else ("岳沉戈 · 动力重拳" if encounter_id == "yue_chenge" else "SENTINEL 反击"))
	if not voyage_config.is_empty():
		detail = str(voyage_config.name)
		if encounter_id == "voyage_spore_drifter" and enemy_turn_count % 3 == 0 and support_heals < 2:
			enemy_health = mini(enemy_max_health, enemy_health + 45)
			support_heals += 1
			raw_damage = 0
			detail += " · 再生孢雾回复45 HP"
		elif encounter_id == "voyage_root_matriarch" and enemy_turn_count % 3 == 0:
			enemy_guard_ratio = 0.6
			detail += " · 根冠屏障展开"
		elif encounter_id == "voyage_tide_acolyte" and repeated_player_action:
			raw_damage *= 1.4
			detail += " · 复诵惩戒"
		elif encounter_id == "voyage_faceless_observer" and enemy_turn_count % 3 == 0:
			game_state.energy = maxi(0, game_state.energy - 18)
			detail += " · 抽取18 MP"
		elif encounter_id == "voyage_mnemonic_choir" and enemy_turn_count % 3 == 0:
			raw_damage *= 1.6
			detail += " · 认知失真"
		elif encounter_id == "voyage_storm_medusa" and enemy_turn_count % 3 == 0:
			game_state.energy = maxi(0, game_state.energy - 20)
			raw_damage *= 1.3
			detail += " · 导电印记 / 抽取20 MP"
		elif encounter_id == "voyage_tide_root" and enemy_turn_count % 3 == 0:
			if bind_immunity_turns <= 0:
				bound_turns = 1
				detail += " · 缠根"
			else:
				detail += " · 喷剂免疫缠根"
	if heavy_attack and encounter_id not in ["voyage_spore_drifter", "voyage_root_matriarch", "voyage_tide_acolyte", "voyage_faceless_observer", "voyage_mnemonic_choir", "voyage_storm_medusa", "voyage_tide_root"]:
		raw_damage *= 1.75
		detail = "蓄力重击"
	if rage:
		raw_damage *= 1.25
		detail += " · 狂暴协议"
	if encounter_id == "yue_chenge" and yue_second_form and enemy_turn_count % 3 == 0:
		raw_damage *= 1.35
		detail += " · 三连震舱"
	if encounter_id == "voyage_ridgebeast" and enemy_health < enemy_max_health * 0.4:
		if enemy_turn_count % 2 == 0:
			raw_damage *= 1.75
			detail += " · 深潮狂怒"
	if not voyage_config.is_empty() and voyage_config.map == "storm_sea" and game_state.voyage.module_choice == "insulation":
		raw_damage *= 0.75
		detail += " · 绝缘组件减伤"
	raw_damage *= enemy_damage_multiplier * game_state.incoming_multiplier()
	if barrier_ready:
		raw_damage *= 0.25
	elif guarding:
		raw_damage *= 0.35
		if heavy_attack:
			counter_ready = true
			detail += " · 完美防御，反击窗口开启"
	guarding = false
	barrier_ready = false
	if bind_immunity_turns > 0:
		bind_immunity_turns -= 1
	var damage := ceili(raw_damage)
	game_state.take_damage(damage)
	player_art.modulate = Color("ff9c91")
	create_tween().tween_property(player_art, "modulate", Color.WHITE, 0.28)
	combat_log.text += "\n%s，造成 %d 点伤害。" % [detail, damage]
	var attack_interval := 2 if encounter_id == "yue_chenge" and yue_second_form else 3
	if (enemy_turn_count + 1) % attack_interval == 0:
		combat_log.text += " 敌方正在蓄力：下一回合建议防御。"
	_update_display()
	if game_state.health == 0:
		phase = Phase.RESOLVING
		combat_log.text = "外骨骼失去响应。K-12 紧急回收协议已启动……"
		await get_tree().create_timer(0.85).timeout
		_end_encounter()
		root.hide()
		player_defeated.emit()
		return
	if encounter_id == "wen_jian" and mind_control_warning and _try_control(randf()):
		combat_log.text += "\n镜中低语封锁了凌霁的行动（连续 %d/2）。" % control_chain
		if _complete_control_overload():
			combat_log.text += " 闻缄强行连控导致魂丝过载，丢失下一次行动；手环建立反击窗口与两回合抗性。"
			_update_display()
			await get_tree().create_timer(0.35).timeout
			phase = Phase.PLAYER_TURN
			_set_actions_enabled(true)
			return
		_update_display()
		await get_tree().create_timer(0.35).timeout
		_enemy_turn()
		return
	if encounter_id == "wen_jian":
		if mi_po_barrier_triggered:
			combat_log.text += "\n弥珀的反相屏障切断了第二次控魂；本次战斗的支援已用尽。"
			mi_po_barrier_triggered = false
		mind_control_warning = false
		var warning_interval: int = _wen_warning_interval()
		if control_immunity_turns == 0 and mi_po_early_warning_pending and enemy_turn_count == maxi(1, warning_interval - 1):
			mi_po_early_warning_pending = false
			mind_control_warning = true
			combat_log.text += "\n弥珀预警：亡者伪声的频谱过于完美。下回合可提前锚定现实。"
		elif control_immunity_turns == 0 and enemy_turn_count % warning_interval == 0:
			mind_control_warning = true
			combat_log.text += "\n控魂预警：镜面出现紫色裂纹。下回合使用【战术防御】锚定现实，可免除失控并开启反击。"
	if encounter_id == "yue_chenge" and yue_second_form and mi_po_yue_support_available:
		mi_po_yue_support_available = false
		combat_log.text += "\n弥珀：‘我只能让星核不回应他一次。凌霁，剩下的由你回答。’下一次裂舰扑杀路线已提前标出。"
	await get_tree().create_timer(0.35).timeout
	phase = Phase.PLAYER_TURN
	_set_actions_enabled(true)
	_update_display()


func _try_control(roll: float) -> bool:
	if encounter_id == "wen_jian" and control_chain >= 1 and mi_po_barrier_available:
		mi_po_barrier_available = false
		mi_po_barrier_triggered = true
		control_chain = 0
		control_immunity_turns = maxi(control_immunity_turns, 1)
		return false
	if not PIRATE_RULES.resolves_control(roll, control_chain, control_immunity_turns):
		if control_chain > 0:
			control_chain = 0
			control_immunity_turns = maxi(control_immunity_turns, 1)
		return false
	control_chain += 1
	player_turns_skipped += 1
	if control_chain >= 2:
		control_immunity_turns = 2
	return true


func _wen_phase() -> int:
	if encounter_id != "wen_jian":
		return 0
	var ratio: float = float(enemy_health) / float(enemy_max_health)
	return 1 if ratio > 0.66 else (2 if ratio > 0.33 else 3)


func _wen_warning_interval() -> int:
	return 3 if _wen_phase() == 1 else (2 if _wen_phase() == 2 else 1)


func _anchor_mind_control() -> bool:
	if encounter_id != "wen_jian" or not mind_control_warning:
		return false
	mind_control_warning = false
	control_chain = 0
	control_immunity_turns = maxi(control_immunity_turns, 2)
	counter_ready = true
	return true


func _complete_control_overload() -> bool:
	if encounter_id != "wen_jian" or control_chain < 2 or control_immunity_turns <= 0:
		return false
	mind_control_warning = false
	counter_ready = true
	return true


func _finish_victory() -> void:
	if victory_resolved:
		return
	if encounter_id == "yue_chenge" and not yue_second_form:
		_start_yue_second_form()
		return
	victory_resolved = true
	if encounter_id == "wen_jian":
		game_state.defeat_wen_jian()
	elif encounter_id == "yue_chenge":
		game_state.defeat_yue_chenge()
	phase = Phase.RESOLVING
	combat_log.text = "SENTINEL 已停机。返回 B7 回收认证记录。" if encounter_id == "main" else ("闻缄的控魂中继已断开。" if encounter_id == "wen_jian" else ("断舰核心崩解，星核抽取锚正在脱离。" if encounter_id == "yue_chenge" else "演练 / 警戒战结束。"))
	_update_display()
	result_title.text = "战斗胜利 / MISSION CLEAR"
	result_detail.text = "回合 %d    造成伤害 %d\n剩余 HP %d/%d    MP %d/%d\n%s" % [enemy_turn_count, total_damage_dealt, game_state.health, game_state.max_health, game_state.energy, game_state.max_energy, "任务奖励将在汇报后结算" if encounter_id == "main" else "战斗记录已写入任务状态"]
	result_panel.show()
	await get_tree().create_timer(0.8).timeout
	result_panel.hide()
	_end_encounter()
	root.hide()
	battle_won.emit()


func _start_yue_second_form() -> void:
	yue_second_form = true
	enemy_max_health = 992
	enemy_health = enemy_max_health
	enemy_damage_multiplier = 2.0
	enemy_art.texture = YUE_CHENGE_BEAST
	guarding = false
	barrier_ready = false
	counter_ready = true
	phase = Phase.PLAYER_TURN
	combat_log.text = "安全限制解除。岳沉戈将神经接口、战斗药剂与攻城装甲压入【断舰兽化】；战斗评级提升至第一形态的三倍。保留的相位偏差为你打开了一次反击窗口。"
	if mi_po_yue_support_available:
		combat_log.text += "\n弥珀已接入星核共振：她将在首次兽化攻势前标出裂舰扑杀路线，不恢复护盾。"
	_set_actions_enabled(true)
	_update_display()


func _update_display() -> void:
	player_art.texture = CHARACTER_ART.portrait(game_state)
	heading_label.text = "B7 收容区 7A  //  COMBAT PROTOCOL" if encounter_id in ["main", "side"] else "基地训练舱  //  SIMULATION"
	enemy_name_label.text = {"main": "SENTINEL · 失控哨兵", "demo": "90 HP · 赤线模拟靶", "practice": "150 HP · 巡逻机演练", "side": "150 HP · 支路警戒机"}.get(encounter_id, "哨兵")
	if encounter_id.begins_with("echo_"):
		heading_label.text = "ECHO-9 / 灰潮盆地 · 战术接触"
		enemy_name_label.text = "观测站守卫 · 220 HP" if encounter_id == "echo_guard" else "信标巡逻机 · 150 HP"
	elif encounter_id == "wen_jian":
		heading_label.text = "蜃心中继舰 / 控魂中枢 · MIND BREAK"
		enemy_name_label.text = "闻缄 · 引魂师"
	elif encounter_id in ["pirate_guard_1", "pirate_guard_2"]:
		heading_label.text = "蜃心中继舰 / BOARDING ACTION"
		enemy_name_label.text = "静默甲板警戒组" if encounter_id == "pirate_guard_1" else "回声舱幻影守卫"
	elif encounter_id == "yue_chenge":
		heading_label.text = "葬潮号 / 主炮脊柱 · FINAL ENGAGEMENT"
		enemy_name_label.text = "岳沉戈 · 断舰兽化" if yue_second_form else "岳沉戈 · 断舰统领"
	elif not voyage_config.is_empty():
		heading_label.text = "涅柔斯-4 / 潮汐盲区 · FIELD CONTACT"
		enemy_name_label.text = str(voyage_config.name)
	action_buttons[0].text = "1  脉冲斩击" + (" · 12 MP" if game_state.equipped_armor == "redline" else "")
	action_buttons[1].text = "2  过载突袭 · %d MP" % (72 if game_state.equipped_armor == "redline" else 60)
	action_buttons[2].text = "3  锚定现实 · 阻断控魂并反击" if encounter_id == "wen_jian" and mind_control_warning else "3  战术防御"
	enemy_health_bar.max_value = enemy_max_health
	enemy_health_bar.value = enemy_health
	player_health_bar.max_value = game_state.max_health
	player_health_bar.value = game_state.health
	player_mp_bar.max_value = game_state.max_energy
	player_mp_bar.value = game_state.energy
	enemy_health_label.text = "%d / %d" % [enemy_health, enemy_max_health]
	player_status_label.text = "凌霁 · LYRA-7     HP %d / %d    MP %d / %d" % [game_state.health, game_state.max_health, game_state.energy, game_state.max_energy]
	player_status_label.text += "\n%s · 受伤 ×%.2f  %s" % [game_state.stage_name(), game_state.incoming_multiplier(), CHARACTER_ART.art_note(game_state)]
	if encounter_id == "wen_jian":
		var phase_names: Array[String] = ["", "镜语试探", "亡者回声", "反噬核心"]
		player_status_label.text += "\n阶段%d·%s · 控魂%s · 连续失控 %d/2 · 坚定 %d回合" % [_wen_phase(), phase_names[_wen_phase()], "预警" if mind_control_warning else "潜伏", control_chain, control_immunity_turns]
		if int(game_state.mi_po.trust) >= 30:
			player_status_label.text += " · 弥珀支援%s" % ("就绪" if mi_po_barrier_available else "频谱在线")
	elif encounter_id == "yue_chenge":
		player_status_label.text += "\n%s · 战斗评级 %s · 重击周期 %d回合" % ["第二形态·断舰兽化" if yue_second_form else "第一形态·断舰统领", "×3" if yue_second_form else "×1", 2 if yue_second_form else 3]
		if yue_second_form and mi_po_yue_support_available:
			player_status_label.text += " · 弥珀已标记下次裂舰扑杀"
	if counter_ready:
		player_status_label.text += "    反击窗口"


func _set_actions_enabled(enabled: bool) -> void:
	for button: Button in action_buttons:
		button.disabled = not enabled


func _build_interface() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var background := TextureRect.new()
	environment_art = background
	background.texture = BATTLE_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.035, 0.05, 0.08)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)

	var heading := _label("B7 收容区 7A  //  COMBAT PROTOCOL", 15, Color("64eee5"))
	heading_label = heading
	heading.position = Vector2(38, 24)
	heading.size = Vector2(600, 30)
	root.add_child(heading)

	player_art = TextureRect.new()
	player_art.texture = PLAYER_IDLE
	player_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player_art.position = Vector2(782, 22)
	player_art.size = Vector2(480, 686)
	player_art.flip_h = true
	player_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root.add_child(player_art)

	enemy_art = TextureRect.new()
	enemy_art.texture = SENTINEL
	enemy_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_art.position = Vector2(60, 175)
	enemy_art.size = Vector2(370, 330)
	enemy_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root.add_child(enemy_art)

	var enemy_name := _label("SENTINEL · 失控哨兵", 22, Color("ffe0a3"))
	enemy_name_label = enemy_name
	enemy_name.position = Vector2(80, 105)
	enemy_name.size = Vector2(340, 32)
	root.add_child(enemy_name)
	enemy_health_bar = ProgressBar.new()
	enemy_health_bar.show_percentage = false
	enemy_health_bar.position = Vector2(80, 144)
	enemy_health_bar.size = Vector2(320, 16)
	enemy_health_bar.add_theme_stylebox_override("fill", _bar_style(Color("d76a69")))
	enemy_health_bar.max_value = ENEMY_MAX_HEALTH
	root.add_child(enemy_health_bar)
	enemy_health_label = _label("", 13, Color("ffffff"))
	enemy_health_label.position = Vector2(180, 143)
	enemy_health_label.size = Vector2(120, 20)
	enemy_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(enemy_health_label)

	var status_panel := PanelContainer.new()
	status_panel.position = Vector2(24, 522)
	status_panel.size = Vector2(530, 176)
	status_panel.add_theme_stylebox_override("panel", _box(Color("0b1824"), Color("32e6db"), 1, 7))
	root.add_child(status_panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	status_panel.add_child(body)
	player_health_bar = ProgressBar.new()
	player_health_bar.show_percentage = false
	player_health_bar.custom_minimum_size.y = 12
	player_health_bar.add_theme_stylebox_override("fill", _bar_style(Color("df7872")))
	body.add_child(player_health_bar)
	player_mp_bar = ProgressBar.new()
	player_mp_bar.show_percentage = false
	player_mp_bar.custom_minimum_size.y = 12
	player_mp_bar.add_theme_stylebox_override("fill", _bar_style(Color("55b9e3")))
	body.add_child(player_mp_bar)
	player_status_label = _label("", 14, Color("bfe7e5"))
	body.add_child(player_status_label)
	combat_log = _label("", 14, Color("d8e8ed"))
	combat_log.custom_minimum_size.y = 64
	body.add_child(combat_log)
	var action_panel := PanelContainer.new()
	action_panel.position = Vector2(572, 236)
	action_panel.size = Vector2(218, 244)
	action_panel.add_theme_stylebox_override("panel", _box(Color(0.04, 0.12, 0.16, 0.93), Color("8bcec1"), 1, 10))
	root.add_child(action_panel)
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	action_panel.add_child(actions)
	actions.add_child(_label("战斗指令", 18, Color("c4f2e3")))
	_add_action_button(actions, "1  脉冲斩击", "attack")
	_add_action_button(actions, "2  过载突袭 · 60 MP", "skill")
	_add_action_button(actions, "3  战术防御", "guard")
	_add_action_button(actions, "4  撤离战斗", "retreat")
	_add_action_button(actions, "道具背包", "items")
	_add_action_button(actions, "技能列表 / 升级解锁", "skills")
	boost_confirmation = ConfirmationDialog.new()
	boost_confirmation.title = "赤线 MP 不足"
	boost_confirmation.ok_button_text = "不增幅攻击"
	boost_confirmation.cancel_button_text = "取消"
	boost_confirmation.confirmed.connect(func() -> void:
		boost_confirmation.hide()
		var action := pending_action
		pending_action = ""
		_perform_action(action, true))
	boost_confirmation.canceled.connect(func() -> void: pending_action = "")
	root.add_child(boost_confirmation)
	choice_panel = PanelContainer.new()
	choice_panel.position = Vector2(540, 220)
	choice_panel.size = Vector2(300, 300)
	choice_panel.add_theme_stylebox_override("panel", _box(Color("0b1824"), Color("32e6db"), 2, 7))
	root.add_child(choice_panel)
	choice_list = VBoxContainer.new()
	choice_panel.add_child(choice_list)
	choice_panel.hide()
	result_panel = PanelContainer.new()
	result_panel.position = Vector2(375, 205)
	result_panel.size = Vector2(530, 285)
	result_panel.z_index = 100
	result_panel.add_theme_stylebox_override("panel", _box(Color(0.025, 0.07, 0.10, 0.97), Color("e6b954"), 3, 12))
	root.add_child(result_panel)
	var result_body := VBoxContainer.new()
	result_body.alignment = BoxContainer.ALIGNMENT_CENTER
	result_body.add_theme_constant_override("separation", 18)
	result_panel.add_child(result_body)
	result_title = _label("战斗胜利 / MISSION CLEAR", 30, Color("ffe6a2"))
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_body.add_child(result_title)
	result_detail = _label("", 18, Color("d8e8ed"))
	result_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_body.add_child(result_detail)
	result_body.add_child(_label("战斗结算完成后自动返回探索", 14, Color("8babb7")))
	result_panel.hide()


func set_environment(texture: Texture2D) -> void:
	environment_art.texture = texture


func _end_encounter() -> void:
	game_state.battle_active = false
	if encounter_id == "demo":
		game_state.health = demo_health
		game_state.energy = demo_energy
		game_state.inventory = demo_inventory.duplicate()


func _open_choices(kind: String) -> void:
	for child: Node in choice_list.get_children():
		choice_list.remove_child(child)
		child.queue_free()
	if kind == "items":
		for item: String in game_state.ITEM_NAMES:
			_choice("%s  ×%d" % [game_state.ITEM_NAMES[item], game_state.inventory[item]], "item:" + item)
		if not voyage_config.is_empty():
			_choice("抗黏附喷剂 · 解除束缚并免疫3回合  ×%d" % int(game_state.voyage.sprays), "item:anti_adhesion_spray")
	else:
		_choice("过载突袭 · %d MP" % (72 if game_state.equipped_armor == "redline" else 60), "skill")
		if game_state.level() >= 4:
			_choice("LV4 电磁穿刺 · %d MP" % (92 if game_state.equipped_armor == "redline" else 80), "pierce")
		if game_state.level() >= 5:
			_choice("LV5 应急屏障 · 45 MP", "barrier")
		choice_list.add_child(_label("以上费用已含赤线增幅\nLV4 电磁穿刺 / LV5 应急屏障", 14, Color("9cb4bf")))
	_choice("返回（不消耗回合）", "")
	choice_panel.show()


func _choice(title: String, action: String) -> void:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 40
	choice_list.add_child(button)
	button.pressed.connect(func() -> void:
		choice_panel.hide()
		if not action.is_empty():
			_perform_action(action))


func _add_action_button(parent: VBoxContainer, title: String, action: String) -> void:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(180, 38)
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(_perform_action.bind(action))
	parent.add_child(button)
	action_buttons.append(button)


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	return style


func _box(color: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
