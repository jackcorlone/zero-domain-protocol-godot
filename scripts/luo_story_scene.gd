extends Control

const LYRA_SHEET := preload("res://assets/characters/lyra-walk-2d-v1.png")
const LUO_PATH: String = "res://assets/npcs/luo-mao-rpg-v1.png"
var motion: Tween


func stage_picture(chapter: int, intimacy: String) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(210, 12)
	size = Vector2(860, 228)
	var backdrop := ColorRect.new()
	backdrop.color = Color("101d2b")
	backdrop.size = size
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var art_name: String = "trust" if chapter < 2 else ("break" if chapter == 5 else "evidence")
	if chapter == 1 and intimacy in ["embrace", "kiss"]:
		art_name = "closeness"
	var art_path: String = "res://assets/story/luo-%s-v1.png" % art_name
	var picture := TextureRect.new()
	picture.position = Vector2(250, 0)
	picture.size = Vector2(610, 228)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(art_path):
		picture.texture = load(art_path) as Texture2D
	add_child(picture)
	var lyra_frame := AtlasTexture.new()
	lyra_frame.atlas = LYRA_SHEET
	lyra_frame.region = Rect2(Vector2.ZERO, LYRA_SHEET.get_size() / 4.0)
	var lyra: TextureRect = _actor(lyra_frame, Vector2(35, 68))
	var luo_texture: Texture2D = load(LUO_PATH) as Texture2D if ResourceLoader.exists(LUO_PATH) else null
	var luo: TextureRect = _actor(luo_texture, Vector2(150, 68))
	var caption := Label.new()
	caption.position = Vector2(12, 196)
	caption.add_theme_font_size_override("font_size", 13)
	caption.text = ["递出装备箱 · 停步致意", "公共休息区 · 保持距离", "读取门禁 · 观察区疑点", "抬手拒绝 · 留出距离", "对照日志 · 放下信任", "后退转身 · 结束往来"][chapter]
	add_child(caption)
	motion = create_tween()
	if chapter == 0:
		var parcel := ColorRect.new()
		parcel.color = Color("b6a478")
		parcel.position = Vector2(152, 145)
		parcel.size = Vector2(24, 16)
		add_child(parcel)
		motion.tween_property(parcel, "position:x", 100.0, 0.8)
	elif chapter == 1 and intimacy in ["embrace", "kiss"]:
		caption.text = "明确同意后靠近 · 仅限这一次"
		motion.tween_property(lyra, "position:x", 112.0, 0.8)
		motion.tween_interval(0.8)
		motion.tween_property(lyra, "position:x", 35.0, 0.6)
	elif chapter in [3, 5]:
		motion.tween_property(lyra, "position:x", 8.0, 0.6)
		motion.tween_property(luo, "modulate", Color("8c8e95"), 0.4)
	else:
		motion.tween_property(picture, "modulate:a", 0.6, 0.35)
		motion.tween_property(picture, "modulate:a", 1.0, 0.35)


func _actor(texture: Texture2D, at: Vector2) -> TextureRect:
	var actor := TextureRect.new()
	actor.texture = texture
	actor.position = at
	actor.size = Vector2(70, 124)
	actor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	actor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	actor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(actor)
	return actor


func _exit_tree() -> void:
	if motion != null and motion.is_valid():
		motion.kill()
