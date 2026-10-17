extends SceneTree

var failed: bool = false
var scene: Node
var state: ZeroDomainGameState


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)


func _puzzle(kind: String, sequence: Array) -> void:
	scene._start_puzzle(kind)
	for action: String in sequence:
		scene._puzzle_choose(action)


func _reset() -> void:
	state.reset()
	state.quest_state = state.QuestState.COMPLETE
	state.echo.accepted = true
	state.saved_location = "landing"
	state.energy = 0
	state.inventory = {"med_gel": 0, "battery": 0, "repair_pack": 0}
	scene._set_location("landing")


func _run() -> void:
	state = root.get_node("GameState")
	state.reset()
	_check(not state.accept_expedition(), "旧主线未完成不能接外勤")
	state.quest_state = state.QuestState.COMPLETE
	_check(state.accept_expedition(), "完成旧主线后可接外勤")
	state.saved_location = "hangar"
	scene = load("res://scenes/expedition.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	_check(scene.location_id == "hangar", "外勤场景应恢复保存的地图")
	scene._boarding()
	scene._close_modals()
	_check(scene.location_id == "hangar" and scene.flight_destination == "", "取消登舰不得出航")
	scene._fly("landing")
	_check(not scene.player.controls_enabled and state.saved_location == "hangar", "航行冻结移动并保留起飞前存档")
	scene._finish_flight()
	scene._finish_flight()
	_check(scene.location_id == "landing" and scene.player.controls_enabled, "跳过航行只能抵达一次并恢复移动")
	var orders := [["highland", "wrecksite", "ravine"], ["highland", "ravine", "wrecksite"], ["wrecksite", "highland", "ravine"], ["wrecksite", "ravine", "highland"], ["ravine", "highland", "wrecksite"], ["ravine", "wrecksite", "highland"]]
	for order: Array in orders:
		_reset()
		for place: String in order:
			scene._set_location(place)
			match place:
				"highland": scene._download_antenna()
				"wrecksite": scene._manifest()
				"ravine": scene._bridge()
			await process_frame
		_check(state.echo.clues.size() == 3 and state.experience == 1890, "六种顺序都能获得三条唯一线索和一次额外探索奖励")
		_check(not state.collect_echo_clue("ravine") and state.experience == 1890, "重复读取不能刷线索和经验")
		scene._set_location("station")
		_puzzle("maintenance", ["旁路", "验压", "开舱"])
		scene._enter_archive()
		_check(scene.location_id == "archive", "维护路线必须进入实际独立档案室")
		scene._core()
		_check(state.echo.outcome == "", "查看档案不自动处置信标")
		scene._confirm_outcome("shutdown")
		scene._core()
		_check(state.echo.outcome == "", "取消最终确认保持未处置")
		scene._resolve_outcome("shutdown")
		_check(state.echo.outcome == "shutdown" and state.energy == 0 and state.health == 860 and state.experience == 1890, "零MP空背包可无战斗完成，奖励待返航汇报")
		_check(not state.resolve_echo("keep"), "最终选择不可改写")
		_check(state.quest_state == state.QuestState.COMPLETE and not state.battle_active, "外勤不得篡改旧主线状态")
	_reset()
	scene._set_location("station")
	scene._enter_archive()
	_check(scene.location_id == "station", "无权限不能进入档案室")
	scene._set_location("highland")
	scene._download_antenna()
	scene._set_location("wrecksite")
	scene._manifest()
	scene._set_location("station")
	scene._permit()
	scene._obtain_permit()
	scene._enter_archive()
	scene._resolve_outcome("keep")
	_check(state.echo.clues.size() == 2 and state.echo.outcome == "keep", "任意两条含运输单线索可协商完成，无需第三条")
	_reset()
	scene._set_location("highland")
	scene._start_puzzle("antenna")
	scene._puzzle_choose("长")
	_check(scene.puzzle_progress == 0 and not state.echo.beacon_on, "错误机关不改变世界")
	_puzzle("antenna", ["短", "长", "短"])
	_check(state.echo.beacon_on and scene.patrol.visible, "修灯标实际出现巡逻机并更新地图")
	scene._set_location("wrecksite")
	_puzzle("rescue", ["泄压", "断电", "开锁"])
	_check(state.echo.rescued and not scene.points.rescue.node.visible, "救援后求救点移除")
	var xp_after_rescue := state.experience
	_puzzle("rescue", ["泄压", "断电", "开锁"])
	_check(state.experience == xp_after_rescue, "救援不可重复领经验")
	scene._set_location("landing")
	_check(scene.points.has("survivor"), "获救NPC应在着陆点出现")
	scene._set_location("ravine")
	_check(scene.bridge_blocker.collision_layer == 1, "断桥初始阻挡行走")
	scene._bridge()
	_puzzle("bridge", ["接地", "供电", "搭桥"])
	_check(scene.bridge_blocker.collision_layer == 0 and scene.bridge_deck.visible, "修桥后真实解除碰撞并显示桥面")
	_puzzle("cache", ["山脊", "河谷", "营地"])
	_check(state.echo.survey_module and state.echo.cache_claimed, "可选宝箱发放导航插件")
	scene._shortcut()
	_check(scene.location_id == "landing", "修桥后高架捷径可返着陆点")
	scene._fly("hangar")
	scene._finish_flight()
	scene._fly("landing")
	scene._finish_flight()
	_check(state.echo.rescued and state.echo.bridge_fixed and state.echo.cache_claimed, "往返不重置永久探索成果")
	state.save_path = "/private/tmp/zero-domain-echo-%d.cfg" % OS.get_process_id()
	state.persistence_enabled = true
	scene._set_location("ravine")
	_check(state.save_progress() == OK, "外勤进度可保存")
	state.reset()
	_check(state.load_progress() and state.saved_scene().ends_with("expedition.tscn") and state.echo.bridge_fixed and state.echo.rescued, "外勤地点和地图状态能读回")
	scene._set_location(state.saved_location)
	_check(scene.bridge_blocker.collision_layer == 0, "读档后桥梁碰撞仍解除")
	# Build an old-format save with real existing fields, then migrate without wiping any of them.
	state.reset()
	state.quest_state = state.QuestState.COMPLETE
	state.gift_status = "accepted"
	state.owned_armors.append("redline")
	state.equipped_armor = "redline"
	state.invitation = "refused"
	var old := ConfigFile.new()
	old.set_value("meta", "version", 1)
	for field: String in state.SAVE_FIELDS:
		old.set_value("progress", field, state.get(field))
	old.save(state.save_path)
	_check(state.load_progress() and not state.echo.accepted and state.invitation == "refused" and state.equipped_armor == "redline" and state.experience == 1840, "旧存档迁移必须保留资源、装备与罗老板选择")
	state.accept_expedition()
	_check(state.save_progress() == OK and FileAccess.file_exists(state.save_path + ".v1-backup"), "首次迁移写入应备份原版存档")
	old.load(state.save_path + ".v1-backup")
	_check(old.get_value("meta", "version") == 1, "备份必须保留旧格式")
	state.persistence_enabled = false
	_reset()
	scene._set_location("station")
	state.health = 1000
	state.energy = 620
	scene._start_echo_battle("echo_guard")
	_check(scene.battle_screen.enemy_health == 220 and not scene.player.controls_enabled, "外勤守卫战正确初始化")
	scene.battle_screen._perform_action("retreat")
	_check(scene.mode == scene.Mode.EXPLORE and not state.echo.guard_down and state.quest_state == state.QuestState.COMPLETE, "撤退不得推进任务")
	scene._start_echo_battle("echo_guard")
	state.health = 1
	scene.battle_screen._perform_action("guard")
	await create_timer(1.5).timeout
	_check(scene.location_id == "landing" and state.health == 350 and state.quest_state == state.QuestState.COMPLETE, "失败回收着陆点且不破坏旧任务")
	scene._set_location("station")
	state.health = 1000
	state.energy = 620
	scene._start_echo_battle("echo_guard")
	for index: int in range(5):
		if state.echo.guard_down:
			break
		scene.battle_screen._perform_action("skill")
		await create_timer(1.0).timeout
	_check(state.echo.guard_down and state.echo.entry == "combat", "正面战斗能获得进入权限")
	state.collect_echo_clue("highland")
	state.collect_echo_clue("ravine")
	scene._enter_archive()
	scene._resolve_outcome("shutdown")
	scene._set_location("station")
	_check(not scene.guard.visible, "关闭信标后守卫停机")
	state.saved_location = "command"
	var credit_before := state.credits
	var xp_before := state.experience
	_check(state.claim_echo_reward() and state.credits == credit_before + 300 and state.experience == xp_before + 300, "返回基地可结算同额基础奖励")
	_check(not state.claim_echo_reward(), "外勤任务奖励只能结算一次")
	if not failed:
		print("ECHO_EXPEDITION_OK")
	quit(1 if failed else 0)
