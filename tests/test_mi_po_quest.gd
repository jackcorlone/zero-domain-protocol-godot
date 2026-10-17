extends SceneTree

var failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _settle() -> void:
	for frame: int in range(4):
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)


func _prepare_ruins(state: ZeroDomainGameState) -> void:
	state.reset()
	state.quest_state = state.QuestState.COMPLETE
	state.echo.accepted = true
	state.echo.outcome = "keep"
	state.echo.reward_claimed = true
	state.ruins.accepted = true
	state.ruins.shelter_secured = true
	state.ruins.clues = ["crater", "observatory"]


func _run() -> void:
	var state: ZeroDomainGameState = root.get_node("GameState")
	var save_path := "/private/tmp/zero-domain-mi-po-%d.cfg" % OS.get_process_id()
	_prepare_ruins(state)
	var experience_before: int = state.experience
	_check(state.meet_mi_po(), "稳定余烬村避难所后应可初遇弥珀")
	_check(state.mi_po.nameplates_taken and not state.complete_mi_po_check("memorial"), "姓名片必须送回纪念墙后才能复命")
	_check(state.complete_mi_po_check("clock") and state.complete_mi_po_check("pulse"), "档案时钟与生命脉冲应可分别校验")
	_check(state.place_mi_po_nameplates() and state.complete_mi_po_check("memorial"), "姓名片归还后应可向弥珀复命")
	_check(state.mi_po.trust == 30 and state.mi_po.joined and state.experience == experience_before + 180, "三项校验应一次性结算180 EXP并将信赖提升到30")
	_check(not state.complete_mi_po_check("clock") and state.experience == experience_before + 180, "校验奖励不得重复领取")

	_check(state.recover_phase_secret(), "两份余烬村记录应可恢复归潮协议")
	_check(not state.set_resonance_node("crater", "invalid"), "共振节点必须拒绝未定义相位")
	_check(state.set_resonance_node("crater", "inverse"), "钻击坑应接受反相")
	_check(state.set_resonance_node("observatory", "silent"), "观测台应接受静默")
	_check(state.set_resonance_node("vault", "positive") and state.mi_po_resonance_ready(), "档案库正相应完成三点共振")
	var credits_before: int = state.credits
	experience_before = state.experience
	_check(state.resolve_mi_po_archive("shared", "civilian") and state.complete_mi_po_quest(), "共同保管并优先平民档案应完成支线")
	_check(state.mi_po.trust == 80 and state.credits == credits_before + 160 and state.experience == experience_before + 220, "最高信赖路线应结算160 CR / 220 EXP")
	_check(not state.complete_mi_po_quest() and state.credits == credits_before + 160, "支线奖励不得重复领取")

	state.save_path = save_path
	state.persistence_enabled = true
	state.saved_location = "ruin_vault"
	_check(state.save_progress() == OK, "弥珀支线应可写入 v5 存档")
	state.mi_po = state.MI_PO_DEFAULTS.duplicate(true)
	_check(state.load_progress() and state.mi_po.trust == 80 and state.mi_po.quest_complete, "信赖、选择与奖励状态应可恢复")

	var legacy := ConfigFile.new()
	_check(legacy.load(save_path) == OK, "应可读取测试存档以构造 v4 迁移")
	legacy.set_value("meta", "version", 4)
	legacy.erase_section("mi_po")
	_check(legacy.save(save_path) == OK, "应可写入缺少弥珀分区的 v4 存档")
	state.mi_po.trust = 80
	_check(state.load_progress() and state.mi_po == state.MI_PO_DEFAULTS, "v4 旧存档应补入弥珀默认状态且不损坏主线")

	_prepare_ruins(state)
	state.saved_location = "ruin_vault"
	change_scene_to_file("res://scenes/expedition.tscn")
	await _settle()
	_check(current_scene.background.texture.resource_path.ends_with("aspera-resonance-archive-map-v1.png"), "地下共振档案库应使用新RPG地图")
	_check(current_scene.points.has("mi_po") and current_scene._objective_point_id() == "mi_po", "弥珀应作为初遇任务点并显示目标引导")
	current_scene._mi_po()
	_check(current_scene.dialogue_name.text == "弥珀" and current_scene.dialogue_portrait.texture == current_scene.MI_PO_ART, "初遇对话应显示弥珀独立立绘")

	state.mi_po = state.MI_PO_DEFAULTS.duplicate(true)
	state.mi_po.met = true
	state.mi_po.nameplates_taken = true
	state.mi_po.nameplates_placed = true
	state.mi_po.clock_restored = true
	state.mi_po.pulse_verified = true
	state.mi_po.memorial_returned = true
	state.mi_po.joined = true
	state.mi_po.trust = 80
	current_scene.battle_screen.setup(state, "wen_jian")
	_check(current_scene.battle_screen.mi_po_early_warning_pending and current_scene.battle_screen.mi_po_barrier_available, "信赖80应开启闻缄战提前预警与一次反相屏障")
	current_scene.battle_screen.control_chain = 1
	_check(not current_scene.battle_screen._try_control(0.0) and current_scene.battle_screen.mi_po_barrier_triggered, "反相屏障应中断第二次连续控魂")
	current_scene.battle_screen._end_encounter()
	current_scene.battle_screen.setup(state, "yue_chenge")
	current_scene.battle_screen._start_yue_second_form()
	_check(current_scene.battle_screen.mi_po_yue_support_available and current_scene.battle_screen.player_status_label.text.contains("已标记下次裂舰扑杀"), "信赖80应在岳沉戈兽化阶段提前显示攻击路线")
	current_scene.battle_screen._end_encounter()

	state.pirate_arc.wen_defeated = true
	state.pirate_arc.finale_unlocked = true
	state.pirate_arc.finale_started = true
	state.pirate_arc.finale_calibration = 3
	state.pirate_arc.yue_defeated = true
	state.pirate_arc.true_end_seen = true
	state.saved_location = "finale"
	change_scene_to_file("res://scenes/finale.tscn")
	await _settle()
	_check(current_scene.dialogue_line.text.contains("弥珀") and current_scene.dialogue_line.text.contains("监督席"), "最高信赖真结局应让弥珀与幸存者进入联合监督席")

	if not failed:
		print("MI_PO_QUEST_OK")
	quit(1 if failed else 0)
