extends SceneTree

const RULES := preload("res://scripts/pirate_arc_rules.gd")
const GAMBLE_SCREEN := preload("res://scripts/qiu_gamble_screen.gd")
var failed: bool = false


func _initialize() -> void:
	var state: ZeroDomainGameState = root.get_node("GameState")
	state.reset()
	var progress: Dictionary = {"gamble_round": 0, "gamble_result": "", "qiu_arrested": false}
	_check(RULES.resolve_gamble_round(progress, "right", 6) == "lost_first", "第一局必须真实败北")
	_check(RULES.resolve_gamble_round(progress, "left", 4) == "retry", "第二局错误箭头不得推进")
	_check(RULES.resolve_gamble_round(progress, "up", 1) == "retry", "第二局低骰点必须失败")
	_check(RULES.resolve_gamble_round(progress, "up", 3) == "won_second", "第二局方向和骰点均达标才取胜")
	_check(RULES.resolve_gamble_round(progress, "left", 2) == "qiu_arrested", "第三局反转后应由执法人员逮捕裘盛")
	_check(progress.qiu_arrested and progress.gamble_round == 3, "裘盛线应在逮捕后一次性完成")
	_check(is_equal_approx(RULES.control_chance(0, 0), 0.40), "首次控制概率应为40%")
	_check(is_equal_approx(RULES.control_chance(1, 0), 0.20), "连续控制概率应递减至20%")
	_check(RULES.control_chance(2, 0) == 0.0 and RULES.control_chance(0, 1) == 0.0, "两连控或抗性期间必须保底免控")
	_check(RULES.resolves_control(0.19, 1, 0) and not RULES.resolves_control(0.20, 1, 0), "控制判定边界应稳定")
	state.pirate_arc.qiu_arrested = true
	state.pirate_arc.gamble_result = "cleared"
	_check(not state.begin_mirror_incursion(), "裘盛被捕后必须先返回基地，不能直接触发卧室镜面")
	_check(state.return_after_qiu_arrest() and state.begin_mirror_incursion(), "返回基地后应开启镜中幻境")
	_check(not state.resolve_mirror_anchor("memory") and state.pirate_arc.mirror_anchor_step == 0, "错误锚点应重置")
	_check(state.resolve_mirror_anchor("bracelet") and state.resolve_mirror_anchor("memory") and state.resolve_mirror_anchor("stars"), "三个现实锚点应破解幻境")
	_check(state.pirate_arc.wen_located and not state.defeat_wen_jian(), "未清理登舰警戒前不能直接结算闻缄")
	_check(state.clear_boarding_wave(0) and state.clear_boarding_wave(1), "应可依次清理两段登舰警戒")
	_check(state.record_wen_defeat() and state.pirate_arc.wen_failures == 1, "闻缄战败应记录但保留可重试状态")
	_check(state.defeat_wen_jian(), "清理两段警戒后应可击败闻缄")
	_check(not state.defeat_wen_jian(), "闻缄战结算不得重复")
	state.save_path = "/private/tmp/zero-domain-pirate-arc-%d.cfg" % OS.get_process_id()
	state.persistence_enabled = true
	_check(state.save_progress() == OK, "海盗章节进度应可写入存档")
	state.pirate_arc = state.PIRATE_ARC_DEFAULTS.duplicate(true)
	_check(state.load_progress() and state.pirate_arc.wen_defeated and state.pirate_arc.returned_base, "逮捕、返航、幻境与闻缄结算应可恢复")
	var screen: CanvasLayer = GAMBLE_SCREEN.new()
	root.add_child(screen)
	await process_frame
	state.reset()
	screen.open(state)
	_check(screen.choose_direction("right") and screen.roll_die(6) == "lost_first", "赌局界面应接受箭头和骰子输入")
	_check(screen.choose_direction("up") and screen.roll_die(1) == "retry", "赌局界面骰点应影响第二局")
	_check(screen.choose_direction("up") and screen.roll_die(3) == "won_second", "赌局界面应推进第二局")
	_check(screen.choose_direction("left") and screen.roll_die(2) == "qiu_arrested", "赌局界面应完成执法逮捕结局")
	var battle := ZeroDomainBattleScreen.new()
	root.add_child(battle)
	await process_frame
	battle.encounter_id = "wen_jian"
	battle.enemy_max_health = 360
	battle.enemy_health = 360
	_check(battle._wen_phase() == 1 and battle._wen_warning_interval() == 3, "闻缄第一阶段应低频预警")
	battle.enemy_health = 180
	_check(battle._wen_phase() == 2 and battle._wen_warning_interval() == 2, "闻缄第二阶段应提高控魂频率")
	battle.enemy_health = 100
	_check(battle._wen_phase() == 3 and battle._wen_warning_interval() == 1, "闻缄第三阶段应每回合施压")
	battle.mind_control_warning = true
	_check(battle._anchor_mind_control() and battle.counter_ready and battle.control_immunity_turns == 2, "玩家应能主动锚定现实并取得反击窗口")
	battle.control_immunity_turns = 0
	_check(battle._try_control(0.0) and battle._try_control(0.0), "闻缄应可实际连续跳过两个玩家回合")
	_check(battle._complete_control_overload() and battle.counter_ready, "第二次失控后闻缄应过载并交出强化反击窗口")
	_check(not battle._try_control(0.0) and battle.player_turns_skipped == 2, "手环保底必须把连续跳过硬限制在两回合")
	battle.queue_free()
	state.reset()
	state.persistence_enabled = true
	state.quest_state = state.QuestState.COMPLETE
	state.echo.accepted = true
	state.echo.outcome = "keep"
	state.echo.reward_claimed = true
	state.ruins.accepted = true
	state.ruins.shelter_secured = true
	state.ruins.clues = ["crater", "observatory"]
	state.ruins.secret_recovered = true
	state.ruins.reported = true
	change_scene_to_file("res://scenes/exploration.tscn")
	for frame: int in range(4):
		await process_frame
	current_scene._open_pirate_arc()
	current_scene._resolve_gamble_input("right", 6)
	current_scene._resolve_gamble_input("up", 3)
	current_scene._resolve_gamble_input("left", 2)
	_check(state.pirate_arc.qiu_arrested, "任务菜单赌局入口应可推进到执法逮捕")
	current_scene._return_after_qiu()
	current_scene._show_mirror_anchor()
	_check(current_scene.luo_story_picture != null and current_scene.luo_story_picture.texture.resource_path.ends_with("wen-jian-mirror-incursion-v1.png"), "镜中入侵应显示闻缄独立CG")
	current_scene._choose_mirror_anchor("bracelet")
	current_scene._choose_mirror_anchor("memory")
	current_scene._choose_mirror_anchor("stars")
	_check(state.pirate_arc.wen_located, "卧室镜中锚点应锁定闻缄")
	current_scene._start_pirate_battle("pirate_guard_1")
	current_scene.battle_screen.enemy_health = 0
	current_scene.battle_screen._finish_victory()
	_check(current_scene.battle_screen.result_panel.visible and current_scene.battle_screen.result_detail.text.contains("造成伤害"), "胜利时应显示战斗结算画面")
	await create_timer(1.0).timeout
	_check(state.pirate_arc.boarding_stage == 1, "静默甲板警戒战后应推进登舰阶段")
	current_scene._start_pirate_battle("pirate_guard_2")
	current_scene.battle_screen.enemy_health = 0
	current_scene.battle_screen._finish_victory()
	await create_timer(1.0).timeout
	_check(state.pirate_arc.boarding_stage == 2, "回声舱警戒战后应开放控魂中枢")
	current_scene._start_wen_battle()
	_check(current_scene.mode == current_scene.Mode.BATTLE and current_scene.battle_screen.encounter_id == "wen_jian", "镜中章节应启动闻缄RPG战")
	_check(current_scene.battle_screen.enemy_art.texture.resource_path.ends_with("wen-jian-combat-v1.png"), "闻缄战应使用独立首领立绘")
	_check(current_scene.battle_screen.environment_art.texture.resource_path.ends_with("wen-jian-core-battle-v1.png"), "闻缄战应使用控魂中枢背景")
	current_scene.battle_screen._end_encounter()
	current_scene.battle_screen.root.hide()
	current_scene.battle_screen.player_defeated.emit()
	_check(current_scene.bad_end_active and current_scene.mode == current_scene.Mode.MODAL and not state.pirate_arc.wen_defeated, "闻缄战败应进入不可续接的BE")
	_check(current_scene.dialogue_header.text.contains("BAD END") and current_scene.dialogue_line.text.contains("防线相信你"), "BE应表现闻缄盗用凌霁的身份签名")
	_check(current_scene.luo_story_picture != null and current_scene.luo_story_picture.texture.resource_path.ends_with("wen-jian-defeat-be-v1.png"), "BE应显示独立战败CG")
	_check(current_scene.dialogue_choices.get_child_count() == 1 and current_scene.dialogue_choices.get_child(0).text == "下一幕", "BE首幕只能前往下一幕")
	current_scene._show_wen_bad_end_page(1)
	_check(current_scene.dialogue_line.text.contains("不是她的意志") and current_scene.luo_story_picture.texture.resource_path.ends_with("wen-jian-defeat-prison-v1.png"), "BE第二幕应显示凌霁被关入航母隔离舱")
	_check(current_scene.dialogue_choices.get_child_count() == 1 and current_scene.dialogue_choices.get_child(0).text == "下一幕", "BE第二幕不能提前读取存档")
	current_scene._show_wen_bad_end_page(2)
	_check(current_scene.dialogue_header.text.contains("FINAL DARKNESS") and current_scene.dialogue_line.text.contains("蓝星星核"), "BE终幕应表现三首领夺取星核后的宇宙黑暗")
	_check(current_scene.luo_story_picture.texture.resource_path.ends_with("wen-jian-defeat-hegemony-v1.png"), "BE终幕应显示海盗三人组称霸CG")
	_check(current_scene.dialogue_choices.get_child_count() == 1 and current_scene.dialogue_choices.get_child(0).text == "下一幕", "宇宙黑暗结局后应继续播放裘盛走向监区的BE收尾")
	current_scene._show_wen_bad_end_page(3)
	_check(current_scene.dialogue_header.text.contains("最后的囚徒") and current_scene.dialogue_line.text.contains("美丽的女战士"), "BE收尾应表现裘盛被释放后走向凌霁所在监区")
	_check(current_scene.luo_story_picture.texture.resource_path.ends_with("qiu-prison-approach-be-v1.png"), "BE收尾应显示裘盛走向监区的远景CG")
	_check(current_scene.dialogue_choices.get_child_count() == 1 and current_scene.dialogue_choices.get_child(0).text.contains("读取最近安全存档"), "BE仅在最后一幕提供读取安全存档")
	_check(current_scene.bad_end_active and not state.pirate_arc.wen_defeated, "三幕BE不得污染任务进度")
	current_scene._reload_wen_checkpoint()
	for frame: int in range(4):
		await process_frame
	_check(current_scene.scene_file_path == "res://scenes/exploration.tscn" and state.pirate_arc.boarding_stage == 2 and not state.pirate_arc.wen_defeated, "BE后必须读取千声室前的安全存档")
	current_scene._start_wen_battle()
	current_scene.battle_screen.enemy_health = 0
	current_scene.battle_screen._finish_victory()
	await create_timer(1.0).timeout
	_check(state.pirate_arc.wen_defeated and current_scene.mode == current_scene.Mode.MODAL, "闻缄胜利应结算并显示收束对白")
	_check(current_scene.dialogue_line.text.contains("不会让你替他们说话"), "收束对白应回应亡者幻境主题")
	current_scene._close_modals()
	_check(current_scene.mode == current_scene.Mode.EXPLORE and current_scene.player.controls_enabled, "关闭结算后应返回探索并恢复控制")
	if not failed:
		print("PIRATE_ARC_OK")
	quit(1 if failed else 0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
