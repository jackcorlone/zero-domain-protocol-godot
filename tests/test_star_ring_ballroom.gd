extends SceneTree

var failed := false


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: ZeroDomainGameState = root.get_node("GameState")
	state.reset()
	state.quest_state = state.QuestState.COMPLETE
	state.echo.accepted = true
	state.saved_location = "ballroom"
	var scene: Node = load("res://scenes/expedition.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	_check(scene.location_id == "ballroom", "已开放 H1 后可恢复到星环舞厅")
	for point_id: String in ["wardrobe", "hostess", "performance", "broker", "lounge", "exit_hangar"]:
		_check(scene.points.has(point_id), "舞厅缺少交互点 " + point_id)
	var gown: Texture2D = load("res://assets/characters/lyra-evening-gown-v1.png")
	var dancer: Texture2D = load("res://assets/characters/lyra-gala-dancer-v1.png")
	_check(gown.get_image().get_pixel(0, 0).a < 0.05 and dancer.get_image().get_pixel(0, 0).a < 0.05, "两套礼服立绘必须带透明背景")
	var credits_before := state.credits
	_check(not state.buy_gala_intel() and state.credits == credits_before, "影响力不足时购买情报不得扣款")
	_check(state.gala_network() and state.gala.influence == 1 and state.credits == credits_before - 100, "公开交流应按明示价格结算")
	_check(state.set_gala_outfit("dancer") and state.gala_perform(), "舞者服应开启一次舞台演出")
	_check(state.gala.influence == 3 and state.energy == 380 and state.credits == credits_before, "演出消耗40 MP并回收100 CR、增加2影响力")
	_check(state.buy_gala_intel(), "达到1影响力后可购买航运情报")
	var old_max_energy := state.max_energy
	_check(state.buy_gala_resonator() and state.max_energy == old_max_energy + 30, "星环偏导器应永久增加30 MP上限")
	_check(not state.buy_gala_resonator(), "偏导器不可重复购买")
	state.save_path = "/private/tmp/zero-domain-gala-%d.cfg" % OS.get_process_id()
	state.persistence_enabled = true
	_check(state.save_progress() == OK, "舞厅进度应可保存")
	state.reset()
	_check(state.load_progress() and state.saved_location == "ballroom" and state.gala.performed and state.gala.resonator, "舞厅服装、交易和装备应能读档恢复")
	if not failed:
		print("STAR_RING_BALLROOM_OK")
	quit(1 if failed else 0)
