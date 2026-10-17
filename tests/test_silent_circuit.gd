extends SceneTree

var failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	seed(11)
	var exploration: Node = load("res://scenes/exploration.tscn").instantiate()
	root.add_child(exploration)
	await process_frame
	var state: ZeroDomainGameState = exploration.game_state
	state.reset()

	_interact(exploration, exploration.command_elevator)
	_assert(exploration.dialogue_choices.get_child_count() == 0, "未接令时电梯不能提供进入选项")
	_interact(exploration, exploration.commander)
	_press_choice(exploration, 0)
	_assert(state.quest_state == state.QuestState.NOT_STARTED, "询问身份不能接受任务")
	_press_choice(exploration, 0)
	_press_choice(exploration, 1)
	_assert(state.quest_state == state.QuestState.ACCEPTED, "任务目标选项应接受任务")
	_interact(exploration, exploration.command_elevator)
	_assert(exploration.dialogue_choices.get_child_count() == 0, "接令但未扫描终端时电梯应锁定")

	_interact(exploration, exploration.supply)
	await process_frame
	_assert(exploration.dialogue_panel.get_global_rect().end.y <= 720, "三选项补给对话不能超出视口")
	_press_choice(exploration, 2)
	_assert(state.supply_choice == state.SupplyChoice.NONE, "暂不使用不能消耗补给")
	_assert(exploration.player.controls_enabled, "关闭补给对话应恢复移动")
	_interact(exploration, exploration.supply)
	state.health = 950
	_press_choice(exploration, 0)
	_assert(state.health == state.max_health, "医疗凝胶不能超出生命上限")
	_assert(not state.take_supply(state.SupplyChoice.BATTERY), "补给只能领取一次")
	_assert(state.energy == 420, "重复领取不能增加 MP")
	_interact(exploration, exploration.supply)
	_assert(exploration.dialogue_line.text == "补给箱已清空。", "领取后应显示清空反馈")

	_interact(exploration, exploration.terminal)
	_press_choice(exploration, 0)
	_assert(state.quest_state == state.QuestState.TERMINAL_SCANNED, "下载应解锁终端状态")
	_interact(exploration, exploration.command_elevator)
	_press_choice(exploration, 1)
	_assert(exploration.location_id == "command", "返回整备不能传送")
	_interact(exploration, exploration.command_elevator)
	_press_choice(exploration, 0)
	_assert(state.quest_state == state.QuestState.IN_B7, "首次进入 B7 应推进状态")
	_assert(exploration.mode == exploration.Mode.EXPLORE, "进入 B7 后应关闭电梯对话")
	_interact(exploration, exploration.sentinel)
	_assert(exploration.dialogue_choices.get_child_count() == 0, "中继决定前不能挑战 Sentinel")
	exploration._start_battle()
	_assert(not exploration.battle_screen.root.visible, "战斗入口不能绕过中继")
	_interact(exploration, exploration.relay)
	_press_choice(exploration, 0)
	_assert(state.relay_choice == state.RelayChoice.CUT_POWER, "切电路线应锁定")
	exploration._choose_relay(state.RelayChoice.MIRROR_SIGNAL)
	_assert(state.relay_choice == state.RelayChoice.CUT_POWER, "不能切换已锁定的路线")
	_assert(exploration.world_shade.color.a > 0.32, "切电应使场景变暗")

	_interact(exploration, exploration.sentinel)
	_press_choice(exploration, 1)
	_assert(state.quest_state == state.QuestState.RELAY_DECIDED, "后退不能开始战斗")
	_interact(exploration, exploration.sentinel)
	_press_choice(exploration, 0)
	var battle: ZeroDomainBattleScreen = exploration.battle_screen
	_assert(battle.enemy_max_health == 170 and battle.enemy_health == 170, "切电后敌人应有 170 HP")
	_assert(is_equal_approx(battle.enemy_damage_multiplier, 0.9), "切电应降低敌方伤害")
	_assert(not exploration.dialogue_panel.visible, "开战应关闭对话")
	state.energy = 0
	battle._perform_action("skill")
	_assert(battle.phase == battle.Phase.PLAYER_TURN and battle.enemy_turn_count == 0, "MP 不足不能消耗回合")
	seed(30)
	randi_range(34, 42)
	var expected_enemy_damage: int = ceili(randi_range(38, 48) * 0.9)
	var health_before_attack: int = state.health
	seed(30)
	battle._perform_action("attack")
	var attack_damage: int = 170 - battle.enemy_health
	_assert(attack_damage >= 34 and attack_damage <= 42, "脉冲斩击必须造成 34–42 伤害")
	_assert(battle.action_buttons[0].disabled, "敌方行动期间应锁定按钮")
	await create_timer(0.9).timeout
	_assert(health_before_attack - state.health == expected_enemy_damage, "切电倍率必须应用于实际敌方伤害")
	var saved_health: int = state.health
	var saved_energy: int = state.energy
	battle._perform_action("retreat")
	_assert(state.health == saved_health and state.energy == saved_energy, "撤离必须保留 HP/MP")
	_assert(state.quest_state == state.QuestState.RELAY_DECIDED, "撤离后应可重新挑战")
	exploration._start_battle()
	_assert(battle.enemy_health == 170 and battle.enemy_turn_count == 0, "重新挑战应重置敌人")
	state.health = 1
	battle._perform_action("guard")
	await create_timer(1.4).timeout
	_assert(exploration.location_id == "command", "失败应回收至指挥中心")
	_assert(state.health == 350, "失败应恢复 35% HP")
	_assert(state.relay_choice == state.RelayChoice.CUT_POWER, "失败必须保留中继决定")
	_assert(exploration.player.controls_enabled, "失败回收后应恢复移动")

	_interact(exploration, exploration.command_elevator)
	_press_choice(exploration, 0)
	exploration._start_battle()
	for index: int in range(8):
		if state.quest_state == state.QuestState.SENTINEL_DEFEATED:
			break
		battle._perform_action("attack")
		await create_timer(1.0).timeout
	_assert(state.quest_state == state.QuestState.SENTINEL_DEFEATED, "切电路线应能以普通攻击完成战斗")
	_assert(state.credits == 480 and state.experience == 1840, "战斗胜利不能结算任务")
	_interact(exploration, exploration.b7_elevator)
	_interact(exploration, exploration.commander)
	_assert(state.quest_state == state.QuestState.SENTINEL_DEFEATED and not state.reward_claimed, "未回收记录不能汇报结算")
	_assert(exploration.mission_text.text.contains("返回 B7"), "提前返回应提示回到 B7")
	_interact(exploration, exploration.command_elevator)
	_press_choice(exploration, 0)
	_assert(exploration.wreck.visible, "往返电梯不能丢失残骸")
	_interact(exploration, exploration.wreck)
	_assert(state.record_recovered == state.RecordRecovered.PARTIAL, "切电后只能回收部分记录")
	_interact(exploration, exploration.b7_elevator)
	_interact(exploration, exploration.commander)
	_assert(state.quest_state == state.QuestState.COMPLETE, "回收并汇报应完成任务")
	_assert(state.credits == 720 and state.experience == 2040, "切电奖励必须为 240 CR、200 EXP")
	_assert(exploration.dialogue_line.text.contains("威胁已隔离"), "切电路线应显示对应结局")
	_interact(exploration, exploration.commander)
	_assert(state.credits == 720 and state.experience == 2040, "重复汇报不能重复奖励")
	_assert(state.quest_log.is_empty(), "部分记录不能解锁完整证据日志")

	state.reset()
	state.accept_quest()
	_assert(state.take_supply(state.SupplyChoice.BATTERY) and state.energy == 540, "电池应恢复 120 MP")
	state.reset()
	state.accept_quest()
	_assert(state.take_supply(state.SupplyChoice.MED_GEL) and state.health == 1000, "凝胶应恢复 140 HP")
	state.reset()
	state.accept_quest()
	state.energy = 590
	_assert(state.take_supply(state.SupplyChoice.BATTERY), "电池应可作为独立补给路线")
	_assert(state.energy == state.max_energy, "电池不能超出 MP 上限")
	if not failed:
		print("SILENT_CIRCUIT_OK")
	quit(1 if failed else 0)


func _interact(exploration: Node, target: Node2D) -> void:
	exploration._close_modals()
	exploration.player.position = target.position
	exploration._interact_with_nearest()


func _press_choice(exploration: Node, index: int) -> void:
	exploration.dialogue_choices.get_child(index).pressed.emit()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	failed = true
