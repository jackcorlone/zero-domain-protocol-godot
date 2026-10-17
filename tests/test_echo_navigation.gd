extends SceneTree

var failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)


func _run() -> void:
	var state: ZeroDomainGameState = root.get_node("GameState")
	state.reset()
	state.quest_state = state.QuestState.COMPLETE
	state.echo.accepted = true
	state.saved_location = "hangar"
	var scene: Node = load("res://scenes/expedition.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	for place: String in scene.MAPS.NAMES:
		scene._set_location(place)
		await physics_frame
		await physics_frame
		_check(scene.background.texture != null, place + " 必须加载真实地图资产")
		var grid := AStarGrid2D.new()
		grid.region = Rect2i(0, 0, 48, 32)
		grid.cell_size = Vector2(32, 32)
		grid.offset = Vector2(16, 16)
		grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
		grid.update()
		var shape := CircleShape2D.new()
		shape.radius = 10
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = shape
		query.collision_mask = 1
		query.exclude = [scene.player.get_rid()]
		for y: int in range(32):
			for x: int in range(48):
				var position := Vector2(x * 32 + 16, y * 32 + 16)
				query.transform = Transform2D(0, position)
				var blocked: bool = not scene.player.movement_bounds.has_point(position) or not scene.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()
				grid.set_point_solid(Vector2i(x, y), blocked)
		var start := Vector2i(scene.player.position / 32)
		_check(not grid.is_point_solid(start), place + " 出生点不得落在障碍物内")
		for id: String in scene.points:
			var point: Node2D = scene.points[id].node
			if not point.visible:
				continue
			var reachable := false
			var center := Vector2i(point.position / 32)
			for y: int in range(maxi(0, center.y - 2), mini(32, center.y + 3)):
				for x: int in range(maxi(0, center.x - 2), mini(48, center.x + 3)):
					var goal := Vector2i(x, y)
					var position := Vector2(x * 32 + 16, y * 32 + 16)
					if grid.is_point_solid(goal) or position.distance_to(point.position) >= 85:
						continue
					var nearest := id
					var distance := position.distance_to(point.position)
					for other: String in scene.points:
						var other_node: Node2D = scene.points[other].node
						if other_node.visible and position.distance_to(other_node.position) < distance:
							nearest = other
							break
					if nearest == id and not grid.get_id_path(start, goal).is_empty():
						reachable = true
			_check(reachable, "%s 的 %s 必须可步行靠近并独立交互" % [place, id])
		await process_frame
	scene._set_location("landing")
	scene.player.position = Vector2(1280, 640)
	Input.action_press("move_right")
	for index: int in range(40):
		await physics_frame
	Input.action_release("move_right")
	_check(scene.player.position.x > 1300, "野外角色不能仍被旧单屏1208像素边界限制")
	_check(scene.camera.is_current() and scene.camera.limit_right == 1536, "野外跟随镜头和地图边界正确")
	var npc: Texture2D = load("res://assets/npcs/echo-engineer-v1.png")
	_check(npc.get_image().get_pixel(0, 0).a < 0.01, "工程员素材必须有透明背景")
	if not failed:
		print("ECHO_NAVIGATION_OK")
	quit(1 if failed else 0)
