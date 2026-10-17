extends SceneTree

var failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	seed(7)
	var exploration_scene: PackedScene = load("res://scenes/exploration.tscn")
	var exploration: Node = exploration_scene.instantiate()
	root.add_child(exploration)
	await process_frame

	exploration.game_state.reset()
	exploration._accept_quest()
	exploration._scan_terminal()
	exploration._set_location("b7")
	exploration._choose_relay(ZeroDomainGameState.RelayChoice.MIRROR_SIGNAL)
	exploration._start_battle()
	await process_frame
	_assert(exploration.mode == exploration.Mode.BATTLE, "接敌后应进入 BATTLE 模式")
	_assert(not exploration.player.controls_enabled, "战斗中必须冻结探索移动")
	_assert(exploration.battle_screen.enemy_max_health == 220, "镜像路线应保留 220 HP")
	_assert(is_equal_approx(exploration.battle_screen.enemy_damage_multiplier, 1.0), "镜像路线应保留标准伤害")

	exploration.battle_screen._perform_action("retreat")
	await process_frame
	_assert(exploration.mode == exploration.Mode.EXPLORE, "撤离后应返回探索模式")
	_assert(exploration.player.controls_enabled, "撤离后应恢复移动")

	exploration._start_battle()
	for index: int in range(3):
		var health_before: int = exploration.game_state.health
		seed(20 + index)
		var raw_damage: float = randi_range(38, 48)
		if index == 2:
			raw_damage *= 1.75
		var expected_damage := ceili(raw_damage * 0.35)
		seed(20 + index)
		exploration.battle_screen._perform_action("guard")
		await create_timer(0.9).timeout
		_assert(health_before - exploration.game_state.health == expected_damage, "常规/第三次重击应按防御倍率结算")
	_assert(exploration.battle_screen.counter_ready, "防住第三次敌方行动后应开启反击窗口")
	_assert(exploration.battle_screen.player_status_label.text.contains("反击窗口"), "反击窗口应持续显示")
	var enemy_health_before: int = exploration.battle_screen.enemy_health
	var energy_before: int = exploration.game_state.energy
	seed(71)
	var expected_counter := floori(randi_range(68, 80) * (1.0 + 0.4 * (1.0 - float(exploration.game_state.health) / 1000.0)) * 1.75)
	seed(71)
	exploration.battle_screen._perform_action("skill")
	var counter_damage: int = enemy_health_before - exploration.battle_screen.enemy_health
	_assert(counter_damage == expected_counter, "反击技能应叠加残血增伤并只在末尾向下取整")
	_assert(not exploration.battle_screen.counter_ready, "反击加成只能消耗一次")
	_assert(exploration.game_state.energy == energy_before - 60, "过载突袭应消耗 60 MP")
	await create_timer(1.0).timeout

	for index: int in range(8):
		if exploration.game_state.quest_state == ZeroDomainGameState.QuestState.SENTINEL_DEFEATED:
			break
		exploration.battle_screen._perform_action("skill")
		await create_timer(1.0).timeout

	_assert(exploration.mode == exploration.Mode.EXPLORE, "胜利后应返回探索模式")
	_assert(exploration.game_state.quest_state == ZeroDomainGameState.QuestState.SENTINEL_DEFEATED, "战斗胜利应进入已击败状态")
	_assert(exploration.game_state.credits == 480, "胜利不能提前发放任务奖励")
	_assert(exploration.game_state.experience == 1840, "胜利不能提前发放任务经验")
	_assert(not exploration.sentinel.visible, "胜利后 Sentinel 应从 B7 地图移除")
	_assert(exploration.wreck.visible, "胜利后应出现可回收残骸")

	exploration._interact_wreck()
	_assert(exploration.game_state.record_recovered == ZeroDomainGameState.RecordRecovered.FULL, "镜像路线应回收完整记录")
	_assert(exploration.dialogue_line.text.contains("欢迎回来"), "完整记录应包含主线悬念")
	exploration._set_location("command")
	exploration._interact_commander()
	_assert(exploration.game_state.credits == 800, "汇报后信用点应从 480 增加到 800")
	_assert(exploration.game_state.experience == 2090, "汇报后经验应从 1840 增加到 2090")
	_assert(exploration.game_state.quest_log == "异常握手源头：核心区下方。", "完整记录结算应新增日志")
	exploration._on_battle_won()
	exploration._interact_commander()
	_assert(exploration.game_state.credits == 800, "重复胜利信号不得重复发放奖励")
	_assert(exploration.game_state.quest_state == ZeroDomainGameState.QuestState.COMPLETE, "重复胜利信号不得使任务状态回退")
	if not failed:
		print("BATTLE_FLOW_OK")
	quit(1 if failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	failed = true
