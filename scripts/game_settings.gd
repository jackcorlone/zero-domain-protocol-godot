extends RefCounted

static var settings_path: String = "user://settings.cfg"


static func apply_saved() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(float(config.get_value("audio", "volume", 0.7)), 0.0, 1.0)))
	AudioServer.set_bus_mute(0, bool(config.get_value("audio", "muted", false)))
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if config.get_value("display", "fullscreen", false) else DisplayServer.WINDOW_MODE_WINDOWED)


static func save_settings() -> Error:
	var config := ConfigFile.new()
	config.set_value("audio", "volume", db_to_linear(AudioServer.get_bus_volume_db(0)))
	config.set_value("audio", "muted", AudioServer.is_bus_mute(0))
	config.set_value("display", "fullscreen", DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN])
	return config.save(settings_path)


static func build_controls(parent: VBoxContainer) -> void:
	var caption := Label.new()
	caption.text = "主音量（作用于游戏音频总线）"
	parent.add_child(caption)
	var volume := HSlider.new()
	volume.min_value = 0
	volume.max_value = 100
	volume.value = roundf(db_to_linear(AudioServer.get_bus_volume_db(0)) * 100.0)
	parent.add_child(volume)
	var mute := CheckButton.new()
	mute.text = "静音"
	mute.button_pressed = AudioServer.is_bus_mute(0)
	parent.add_child(mute)
	var fullscreen := CheckButton.new()
	fullscreen.text = "全屏模式"
	fullscreen.button_pressed = DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	parent.add_child(fullscreen)
	var feedback := Label.new()
	feedback.text = "设置独立保存，不改变任务进度。"
	parent.add_child(feedback)
	volume.value_changed.connect(func(value: float) -> void:
		AudioServer.set_bus_volume_db(0, linear_to_db(value / 100.0))
		caption.text = "主音量 · %d%%" % int(value)
		feedback.text = "设置已保存" if save_settings() == OK else "设置保存失败")
	mute.toggled.connect(func(enabled: bool) -> void:
		AudioServer.set_bus_mute(0, enabled)
		feedback.text = "设置已保存" if save_settings() == OK else "设置保存失败")
	fullscreen.toggled.connect(func(enabled: bool) -> void:
		if DisplayServer.get_name() != "headless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)
		feedback.text = "设置已保存" if save_settings() == OK else "设置保存失败")
