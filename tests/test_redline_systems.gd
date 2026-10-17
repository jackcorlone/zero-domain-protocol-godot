extends SceneTree

var failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)


func _run() -> void:
	var scene: Node = load("res://scenes/exploration.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var state: ZeroDomainGameState = scene.game_state
	var battle: ZeroDomainBattleScreen = scene.battle_screen
	state.reset()
	for sample: Array in [[1000, 0, 1.0, 1.0], [501, 0, 1.0, 1.0], [500, 0, 1.0, 1.0], [499, 1, 1.15, 1.15], [251, 1, 1.15, 1.15], [250, 1, 1.15, 1.15], [249, 2, 1.30, 1.35], [1, 2, 1.30, 1.35]]:
		state.health = sample[0]
		_check(state.armor_stage() == sample[1], "严格低于50%/25%才进入下一阶段")
		_check(scene.CHARACTER_ART.damage_path(state).ends_with("stage-%d-v1.png" % sample[1]), "立绘路径必须与血量阶段一致")
		_check(is_equal_approx(state.speed_multiplier(), sample[2]), "探索速度应按阶段计算")
		_check(is_equal_approx(state.incoming_multiplier(), sample[3]), "受伤倍率应按阶段计算")
		_check(is_equal_approx(state.attack_multiplier(), 1.0 + 0.4 * (1.0 - float(sample[0]) / 1000)), "残血增伤应连续")
	state.health = 0
	_check(state.attack_multiplier(true, true) == 0.0, "倒地后不得攻击")
	_check(state.stage_name() == "失去战斗能力", "零血量显示倒地状态")
	state.max_health = 1200
	for sample: Array in [[600, 0], [599, 1], [300, 1], [299, 2]]:
		state.health = sample[0]
		_check(state.armor_stage() == sample[1], "升级后按最大HP比例而非固定血量判断")
	state.reset()
	state.health = 499
	_check(scene.CHARACTER_ART.portrait(state).resource_path.ends_with("lyra-heavy-stage-1-v1.png"), "重甲低于50%时应切换透明战损立绘")
	state.health = 249
	_check(scene.CHARACTER_ART.portrait(state).resource_path.ends_with("lyra-heavy-stage-1-v1.png") and scene.CHARACTER_ART.art_note(state).contains("重度战损差分待补"), "重度差分缺失时应明确回退到一阶段，而非完整立绘")
	state.reset()
	state.health = 249
	_check(state.use_item("repair_pack") and state.health == 699 and state.armor_stage() == 0, "治疗可从二阶段恢复正常")
	state.health = 1000
	var count: int = state.inventory.med_gel
	_check(not state.use_item("med_gel") and state.inventory.med_gel == count, "满血道具不消耗")
	state.inventory.battery = 9
	_check(not state.buy_item("battery") and state.credits == 480, "物品上限不扣钱")
	state.inventory.battery = 0
	state.credits = 59
	_check(not state.buy_item("battery") and state.inventory.battery == 0, "信用点不足不能购买")
	state.credits = 60
	_check(state.buy_item("battery") and state.credits == 0 and state.inventory.battery == 1, "独立商店精确扣款")
	state.reset()
	_check(state.accept_redline() and state.equipped_armor == "heavy", "接收不自动穿戴")
	_check(not state.accept_redline() and state.owned_armors.count("redline") == 1, "服装不可重复领取")
	_check(state.equip_armor("redline"), "赤线应可穿戴")
	state.health = 1
	_check(state.attack_multiplier(true, true) == 4.0 and is_equal_approx(state.incoming_multiplier(), 2.7), "赤线攻击封顶4倍、重损受伤2.7倍")
	state.battle_active = true
	_check(not state.equip_armor("heavy") and not state.return_redline(), "战斗中不能换装或退还")
	state.battle_active = false
	_check(not state.accept_batteries(), "未实际使用赤线不能领取后续礼物")
	state.redline_used = true
	state.inventory.battery = 8
	_check(not state.accept_batteries() and state.battery_gift_status == "new", "两枚礼物必须全部放得下")
	state.inventory.battery = 2
	_check(state.accept_batteries() and state.inventory.battery == 4, "后续礼物数量为2")
	_check(not state.accept_batteries() and state.inventory.battery == 4, "后续礼物只可领取一次")
	_check(state.return_redline() and state.equipped_armor == "heavy" and not state.accept_redline(), "退还回重甲并阻止重复索取")
	state.reset()
	state.experience = 2500
	state.grant_reward(0, 1600)
	_check(state.level() == 5 and state.max_health == 1160 and state.health == 1020 and state.max_energy == 680 and state.energy == 480, "跨级仅补上限增量，不全恢复")
	state.module_owned = true
	_check(state.toggle_module() and state.max_energy == 720 and state.energy == 480, "模块提高上限不免费回蓝")
	state.energy = 720
	_check(state.toggle_module() and state.energy == 680, "卸模块限制当前MP")
	state.reset()
	state.accept_redline()
	state.equip_armor("redline")
	state.health = 1000
	state.energy = 12
	scene._start_optional_battle("demo")
	_check(battle.enemy_health == 90, "演示靶HP为90")
	battle._perform_action("attack")
	_check(battle.enemy_health == 0 and state.energy == 0 and state.redline_used, "12MP普攻可一击击倒90HP演示靶")
	await create_timer(1.0).timeout
	_check(state.health == 1000 and state.energy == 12 and state.experience == 1840 and state.credits == 480, "演示结算恢复状态且无奖励")
	_check(state.quest_state == state.QuestState.NOT_STARTED and not state.battle_active, "演示不得推进主线")
	state.energy = 71
	scene._start_optional_battle("practice")
	battle._perform_action("skill")
	_check(battle.boost_confirmation.visible and state.energy == 71 and battle.enemy_turn_count == 0, "71MP技能缺赤线增幅费时须确认")
	battle.boost_confirmation.hide()
	battle.boost_confirmation.canceled.emit()
	_check(battle.phase == battle.Phase.PLAYER_TURN and battle.enemy_health == 150, "取消不消耗回合")
	battle._perform_action("skill")
	battle.boost_confirmation.confirmed.emit()
	_check(state.energy == 11 and battle.enemy_health >= 70 and battle.enemy_health <= 82, "确认不增幅时只扣60MP且不乘3")
	await create_timer(0.9).timeout
	battle._perform_action("retreat")
	state.energy = 72
	scene._start_optional_battle("practice")
	battle._perform_action("skill")
	_check(state.energy == 0 and battle.enemy_health == 0, "72MP可完整执行赤线技能")
	await create_timer(1.0).timeout
	_check(state.experience == 1930 and state.credits == 500 and state.quest_state == state.QuestState.NOT_STARTED, "演练只奖励90EXP和20CR且不变更主线")
	scene._on_battle_won()
	_check(state.experience == 1930, "重复胜利回调不能重复奖励")
	state.equip_armor("heavy")
	state.health = 1000
	scene._start_optional_battle("practice")
	count = state.inventory.med_gel
	battle._perform_action("item:med_gel")
	_check(battle.phase == battle.Phase.PLAYER_TURN and state.inventory.med_gel == count, "战斗满血药不耗回合")
	state.health = 100
	battle._perform_action("item:med_gel")
	_check(state.health == 350 and state.inventory.med_gel == count - 1 and battle.phase == battle.Phase.ENEMY_TURN, "有效用药消耗回合并重算战损")
	await create_timer(0.9).timeout
	battle._perform_action("retreat")
	state.reset()
	state.accept_quest()
	# Shield and damage stack verification uses independent arithmetic and seeded base rolls.
	state.experience = 4000
	state.health = 300
	state.energy = 620
	scene._start_optional_battle("practice")
	seed(41)
	var shield_damage := ceili(randi_range(38, 48) * 0.8 * 1.15 * 0.25)
	seed(41)
	battle._perform_action("barrier")
	_check(state.energy == 575, "LV5屏障消耗45MP")
	await create_timer(0.9).timeout
	_check(state.health == 300 - shield_damage and not battle.counter_ready, "屏障与阶段相乘且不生成反击")
	battle._perform_action("retreat")
	state.accept_redline()
	state.equip_armor("redline")
	state.health = 800
	state.energy = 100
	var demo_items: Dictionary = state.inventory.duplicate()
	scene._start_optional_battle("demo")
	battle._perform_action("item:med_gel")
	await create_timer(0.9).timeout
	battle._perform_action("retreat")
	_check(state.health == 800 and state.energy == 100 and state.inventory == demo_items, "演示撤退恢复入场资源且不能套出治疗")
	scene._start_optional_battle("demo")
	state.health = 1
	battle._perform_action("guard")
	await create_timer(1.5).timeout
	_check(state.health == 800 and state.energy == 100 and not state.battle_active, "演示失败也恢复入场资源")
	state.reset()
	state.accept_quest()
	state.quest_state = state.QuestState.TERMINAL_SCANNED
	scene._set_location("b7")
	scene._interact_side_terminal()
	_check(not state.side_patrol_defeated and scene.dialogue_line.text.contains("150 HP"), "支路必须事先警示额外巡逻")
	state.side_patrol_defeated = true
	scene._interact_side_terminal()
	scene._puzzle_input("认证")
	_check(scene.puzzle_step == 0 and not state.chest_claimed, "错误解谜不得发奖")
	for key: String in ["接地", "供能", "认证"]:
		scene._puzzle_input(key)
	_check(state.chest_claimed and state.evidence_found and state.module_owned and "composite" in state.owned_armors and state.inventory.repair_pack == 2, "正确解谜奖励齐全")
	_check(not state.claim_chest(), "宝箱不能重复领取")
	scene._set_location("command")
	scene.luo_dialogue.open()
	await process_frame
	_check(scene.dialogue_panel.get_global_rect().end.y <= 720, "罗老板多选项对话必须适配视口")
	scene.luo_dialogue.decline_gift()
	_check(state.gift_status == "declined" and state.quest_state == state.QuestState.IN_B7, "拒绝礼物不破坏主线")
	scene.luo_dialogue.accept_gift()
	scene.luo_dialogue._respond("private")
	scene.luo_dialogue._respond("refused")
	_check(state.invitation == "refused" and "redline" in state.owned_armors, "赴约后仍能拒绝且保留装备")
	scene.luo_dialogue._expose()
	_check(not state.contact_ended and state.luo_exposed, "前段供货疑点不应提前触发最终决裂")
	scene.luo_dialogue._respond("ended")
	_check(state.buy_item("battery"), "结束私人关系后独立商店仍可用")
	state.save_path = "/private/tmp/zero-domain-redline-test-%d.cfg" % OS.get_process_id()
	state.persistence_enabled = true
	_check(state.save_progress() == OK, "存档应写入临时测试路径")
	var saved_credits := state.credits
	state.reset()
	_check(state.load_progress() and state.chest_claimed and state.luo_exposed and state.credits == saved_credits, "重载应保留宝箱、NPC选择和资源")
	_check(not state.claim_chest() and not state.accept_redline(), "重载不得刷新一次性奖励")
	var config := ConfigFile.new()
	config.load(state.save_path)
	config.set_value("progress", "health", -10)
	config.save(state.save_path)
	var saved_health := state.health
	_check(not state.load_progress() and state.health == saved_health, "损坏存档拒绝载入且不覆盖运行态")
	if not failed:
		print("REDLINE_SYSTEMS_OK")
	quit(1 if failed else 0)
