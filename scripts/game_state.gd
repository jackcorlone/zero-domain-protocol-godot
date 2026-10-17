class_name ZeroDomainGameState
extends Node

enum QuestState {
	NOT_STARTED,
	ACCEPTED,
	TERMINAL_SCANNED,
	IN_B7,
	RELAY_DECIDED,
	BATTLE_IN_PROGRESS,
	SENTINEL_DEFEATED,
	RECORD_RECOVERED,
	COMPLETE,
}
enum SupplyChoice { NONE, MED_GEL, BATTERY }
enum RelayChoice { NONE, CUT_POWER, MIRROR_SIGNAL }
enum RecordRecovered { NONE, PARTIAL, FULL }

var max_health: int = 1000
var health: int = 860
var max_energy: int = 620
var energy: int = 420
var credits: int = 480
var experience: int = 1840
var next_experience: int = 2600

var quest_state: QuestState = QuestState.NOT_STARTED
var supply_choice: SupplyChoice = SupplyChoice.NONE
var relay_choice: RelayChoice = RelayChoice.NONE
var record_recovered: RecordRecovered = RecordRecovered.NONE
var reward_claimed: bool = false
var quest_log: String = ""

const ITEM_NAMES := {"med_gel": "医疗凝胶 · HP +25%", "battery": "标准电池 · MP +20%", "repair_pack": "修复包 · HP +45%"}
const ARMOR_NAMES := {"heavy": "制式重甲", "redline": "赤线战术服", "composite": "复合护甲"}
const LEVEL_THRESHOLDS := [0, 600, 1500, 2600, 4000]
var inventory: Dictionary = {"med_gel": 2, "battery": 2, "repair_pack": 1}
var owned_armors: Array[String] = ["heavy"]
var equipped_armor: String = "heavy"
var battle_active: bool = false
var gift_status: String = "new"
var redline_used: bool = false
var battery_gift_status: String = "new"
var invitation: String = "none"
var contact_ended: bool = false
var evidence_found: bool = false
var luo_exposed: bool = false
var chest_claimed: bool = false
var module_owned: bool = false
var module_equipped: bool = false
var route_known: bool = false
var side_patrol_defeated: bool = false
var saved_location: String = "command"
var persistence_enabled: bool = false
var save_path: String = "user://progress-redline-v1.cfg"
var last_save_error: Error = OK
const SAVE_FIELDS := ["max_health", "health", "max_energy", "energy", "credits", "experience", "next_experience", "quest_state", "supply_choice", "relay_choice", "record_recovered", "reward_claimed", "quest_log", "inventory", "owned_armors", "equipped_armor", "gift_status", "redline_used", "battery_gift_status", "invitation", "contact_ended", "evidence_found", "luo_exposed", "chest_claimed", "module_owned", "module_equipped", "route_known", "side_patrol_defeated", "saved_location"]
const ECHO_LOCATIONS := ["hangar", "ballroom", "landing", "highland", "wrecksite", "ravine", "station", "archive"]
const RUIN_LOCATIONS := ["ruined_village", "ruin_vault"]
const VOYAGE_LOCATIONS := ["starport", "tentacle_field", "eldritch_ruins", "storm_sea"]
const ECHO_DEFAULTS := {"accepted": false, "visited": [], "clues": [], "beacon_on": false, "rescued": false, "bridge_fixed": false, "cache_claimed": false, "entry": "", "outcome": "", "reward_claimed": false, "guard_down": false, "patrol_down": false, "survey_module": false}
var echo: Dictionary = ECHO_DEFAULTS.duplicate(true)
const RUINS_DEFAULTS := {"accepted": false, "visited": [], "shelter_secured": false, "clues": [], "secret_recovered": false, "reported": false}
var ruins: Dictionary = RUINS_DEFAULTS.duplicate(true)
const MI_PO_DEFAULTS := {
	"met": false,
	"nameplates_taken": false,
	"nameplates_placed": false,
	"clock_restored": false,
	"pulse_verified": false,
	"memorial_returned": false,
	"trust": 0,
	"joined": false,
	"resonance_nodes": {},
	"archive_recovered": false,
	"shared_custody": false,
	"civilian_archive_first": false,
	"module_claimed": false,
	"quest_complete": false,
	"reward_claimed": false,
}
var mi_po: Dictionary = MI_PO_DEFAULTS.duplicate(true)
const VOYAGE_DEFAULTS := {"accepted": false, "visited": [], "module_choice": "", "sprays": 0, "defeated": [], "materials": {}}
var voyage: Dictionary = VOYAGE_DEFAULTS.duplicate(true)
const GALA_DEFAULTS := {"outfit": "evening", "influence": 0, "networked": false, "performed": false, "intel": false, "resonator": false}
var gala: Dictionary = GALA_DEFAULTS.duplicate(true)
const LUO_STORY_DEFAULTS := {"stage": 0, "intimacy": "none", "disposition": "none"}
var luo_story: Dictionary = LUO_STORY_DEFAULTS.duplicate(true)
const PIRATE_ARC_DEFAULTS := {"gamble_round": 0, "gamble_result": "", "qiu_arrested": false, "returned_base": false, "mirror_anchor_step": 0, "mirror_cleared": false, "wen_located": false, "boarding_stage": 0, "wen_defeated": false, "wen_failures": 0, "finale_unlocked": false, "finale_started": false, "finale_calibration": 0, "yue_defeated": false, "true_end_seen": false}
var pirate_arc: Dictionary = PIRATE_ARC_DEFAULTS.duplicate(true)
var needs_v1_backup: bool = false


func saved_scene() -> String:
	if saved_location == "finale":
		return "res://scenes/finale.tscn"
	return "res://scenes/expedition.tscn" if saved_location in ECHO_LOCATIONS + RUIN_LOCATIONS + VOYAGE_LOCATIONS else "res://scenes/exploration.tscn"


func accept_voyage() -> bool:
	if not echo.reward_claimed or voyage.accepted:
		return false
	voyage.accepted = true
	quest_log += "\n潮汐盲区：前往 H1 星港候机环，调查涅柔斯-4 异常潮讯。"
	return true


func choose_voyage_module(choice: String) -> bool:
	if not voyage.accepted or voyage.module_choice != "" or choice not in ["insulation", "battery"]:
		return false
	if choice == "battery" and not add_item("battery", 2):
		return false
	voyage.module_choice = choice
	return true


func claim_anti_adhesion_spray() -> bool:
	if not voyage.accepted or voyage.sprays > 0:
		return false
	voyage.sprays = 1
	return true


func record_voyage_victory(encounter_id: String, reward_credits: int, reward_experience: int, drop_name: String) -> bool:
	if not voyage.accepted or encounter_id in voyage.defeated:
		return false
	voyage.defeated.append(encounter_id)
	voyage.materials[drop_name] = int(voyage.materials.get(drop_name, 0)) + 1
	grant_reward(reward_credits, reward_experience)
	return true


func set_gala_outfit(outfit: String) -> bool:
	if battle_active or outfit not in ["evening", "dancer"]:
		return false
	gala.outfit = outfit
	return true


func gala_network() -> bool:
	if gala.networked or credits < 100:
		return false
	credits -= 100
	gala.networked = true
	gala.influence += 1
	grant_reward(0, 120)
	return true


func gala_perform() -> bool:
	if gala.performed or gala.outfit != "dancer" or energy < 40:
		return false
	energy -= 40
	credits += 100
	gala.influence += 2
	gala.performed = true
	return true


func buy_gala_intel() -> bool:
	if gala.intel or credits < 70 or gala.influence < 1:
		return false
	credits -= 70
	gala.intel = true
	grant_reward(0, 80)
	quest_log += "\n星环舞厅：取得名流航运清单，发现一批未登记的相位装备。"
	return true


func buy_gala_resonator() -> bool:
	if gala.resonator or credits < 160 or gala.influence < 2:
		return false
	credits -= 160
	gala.resonator = true
	max_energy += 30
	energy += 30
	return true


func gala_relax() -> bool:
	if credits < 30 or (health == max_health and energy == max_energy):
		return false
	credits -= 30
	health = mini(max_health, health + ceili(max_health * 0.25))
	energy = mini(max_energy, energy + ceili(max_energy * 0.25))
	return true


func accept_expedition() -> bool:
	if quest_state != QuestState.COMPLETE or echo.accepted:
		return false
	echo.accepted = true
	return true


func collect_echo_clue(source: String) -> bool:
	if not echo.accepted or source not in ["highland", "wrecksite", "ravine"] or source in echo.clues:
		return false
	echo.clues.append(source)
	if echo.clues.size() == 3:
		grant_reward(0, 50)
	return true


func resolve_echo(outcome: String) -> bool:
	if not echo.accepted or echo.clues.size() < 2 or echo.entry == "" or echo.outcome != "" or outcome not in ["keep", "shutdown"]:
		return false
	echo.outcome = outcome
	return true


func claim_echo_reward() -> bool:
	if echo.outcome == "" or echo.reward_claimed or saved_location != "command":
		return false
	echo.reward_claimed = true
	grant_reward(300, 300)
	quest_log += "\n回声之外：三年前的 LYRA-7 返航请求。" + ("信标保持运行。" if echo.outcome == "keep" else "信标已关闭。")
	return true


func accept_ruins_mission() -> bool:
	if not echo.reward_claimed or ruins.accepted:
		return false
	ruins.accepted = true
	return true


func collect_ruins_clue(source: String) -> bool:
	if not ruins.accepted or source not in ["crater", "memorial", "observatory"] or source in ruins.clues:
		return false
	ruins.clues.append(source)
	return true


func secure_ruins_shelter() -> bool:
	if not ruins.accepted or ruins.shelter_secured:
		return false
	ruins.shelter_secured = true
	return true


func recover_phase_secret() -> bool:
	if not ruins.accepted or not ruins.shelter_secured or ruins.clues.size() < 2 or ruins.secret_recovered:
		return false
	ruins.secret_recovered = true
	return true


func claim_ruins_reward() -> bool:
	if not ruins.secret_recovered or ruins.reported or saved_location != "command":
		return false
	ruins.reported = true
	grant_reward(450, 500)
	quest_log += "\n灰烬遗言：已回收「归潮协议」，可用于切断航母抽取锁。"
	return true


func meet_mi_po() -> bool:
	if not ruins.accepted or not ruins.shelter_secured or mi_po.met:
		return false
	mi_po.met = true
	mi_po.nameplates_taken = true
	return true


func complete_mi_po_check(check_id: String) -> bool:
	if not mi_po.met or check_id not in ["clock", "pulse", "memorial"]:
		return false
	var field: String = {"clock": "clock_restored", "pulse": "pulse_verified", "memorial": "memorial_returned"}[check_id]
	if bool(mi_po[field]) or (check_id == "memorial" and not mi_po.nameplates_placed):
		return false
	mi_po[field] = true
	_promote_mi_po_after_checks()
	return true


func place_mi_po_nameplates() -> bool:
	if not mi_po.met or not mi_po.nameplates_taken or mi_po.nameplates_placed:
		return false
	mi_po.nameplates_placed = true
	return true


func _promote_mi_po_after_checks() -> void:
	if mi_po.trust == 0 and mi_po.clock_restored and mi_po.pulse_verified and mi_po.memorial_returned:
		mi_po.trust = 30
		mi_po.joined = true
		grant_reward(0, 180)


func set_resonance_node(node_id: String, phase_value: String) -> bool:
	if mi_po.trust < 30 or not ruins.secret_recovered or mi_po.archive_recovered:
		return false
	if node_id not in ["crater", "observatory", "vault"] or phase_value not in ["positive", "inverse", "silent"]:
		return false
	mi_po.resonance_nodes[node_id] = phase_value
	return true


func mi_po_resonance_ready() -> bool:
	return mi_po.resonance_nodes.get("crater", "") == "inverse" and mi_po.resonance_nodes.get("observatory", "") == "silent" and mi_po.resonance_nodes.get("vault", "") == "positive"


func reset_mi_po_resonance() -> void:
	mi_po.resonance_nodes.clear()


func resolve_mi_po_archive(custody: String, priority: String) -> bool:
	if mi_po.archive_recovered or not mi_po_resonance_ready():
		return false
	if custody not in ["shared", "omega"] or priority not in ["civilian", "military"]:
		return false
	mi_po.archive_recovered = true
	mi_po.shared_custody = custody == "shared"
	mi_po.civilian_archive_first = priority == "civilian"
	mi_po.module_claimed = priority == "military"
	return true


func complete_mi_po_quest() -> bool:
	if not mi_po.archive_recovered or mi_po.quest_complete:
		return false
	mi_po.quest_complete = true
	if mi_po.shared_custody and mi_po.civilian_archive_first:
		mi_po.trust = 80
	if not mi_po.reward_claimed:
		mi_po.reward_claimed = true
		grant_reward(160, 220)
	quest_log += "\n为活者调弦：阿斯佩拉生活档案已完成转运，弥珀信赖 %d。" % mi_po.trust
	return true


func begin_mirror_incursion() -> bool:
	return pirate_arc.qiu_arrested and pirate_arc.returned_base and not pirate_arc.mirror_cleared


func return_after_qiu_arrest() -> bool:
	if not pirate_arc.qiu_arrested or pirate_arc.returned_base:
		return false
	pirate_arc.returned_base = true
	return true


func clear_mirror_incursion() -> bool:
	if not begin_mirror_incursion():
		return false
	pirate_arc.mirror_cleared = true
	pirate_arc.wen_located = true
	quest_log += "\n引魂师：镜中幻境已破解，闻缄的控魂中继坐标已锁定。"
	return true


func resolve_mirror_anchor(anchor: String) -> bool:
	if not begin_mirror_incursion():
		return false
	var sequence: Array[String] = ["bracelet", "memory", "stars"]
	if anchor != sequence[int(pirate_arc.mirror_anchor_step)]:
		pirate_arc.mirror_anchor_step = 0
		return false
	pirate_arc.mirror_anchor_step += 1
	if pirate_arc.mirror_anchor_step == sequence.size():
		return clear_mirror_incursion()
	return true


func defeat_wen_jian() -> bool:
	if not pirate_arc.wen_located or pirate_arc.boarding_stage < 2 or pirate_arc.wen_defeated:
		return false
	pirate_arc.wen_defeated = true
	pirate_arc.finale_unlocked = true
	max_health += 160
	health = max_health
	max_energy += 60
	energy = max_energy
	quest_log += "\n镜中入侵：魂丝反写完成，已获得「真实指令校验签名」。"
	return true


func begin_finale() -> bool:
	if pirate_arc.wen_defeated and not pirate_arc.finale_unlocked:
		pirate_arc.finale_unlocked = true
	if not pirate_arc.finale_unlocked or not pirate_arc.wen_defeated or pirate_arc.yue_defeated:
		return false
	if not pirate_arc.finale_started:
		pirate_arc.finale_started = true
		health = max_health
		energy = max_energy
	saved_location = "finale"
	return true


func calibrate_finale_node(step: int) -> bool:
	if not pirate_arc.finale_started or step != pirate_arc.finale_calibration or step not in range(3):
		return false
	pirate_arc.finale_calibration += 1
	return true


func defeat_yue_chenge() -> bool:
	if not pirate_arc.finale_started or pirate_arc.finale_calibration < 3 or pirate_arc.yue_defeated:
		return false
	pirate_arc.yue_defeated = true
	pirate_arc.true_end_seen = true
	quest_log += "\n归潮：岳沉戈的断舰核心已毁，蓝星星核回归稳定轨道。"
	grant_reward(1200, 1200)
	return true


func record_wen_defeat() -> bool:
	if not pirate_arc.wen_located or pirate_arc.boarding_stage < 2 or pirate_arc.wen_defeated:
		return false
	pirate_arc.wen_failures += 1
	return true


func clear_boarding_wave(wave: int) -> bool:
	if not pirate_arc.wen_located or wave != pirate_arc.boarding_stage or wave not in [0, 1]:
		return false
	pirate_arc.boarding_stage += 1
	return true


func save_progress() -> Error:
	if not persistence_enabled or battle_active:
		return OK
	var config := ConfigFile.new()
	config.set_value("meta", "version", 5)
	config.set_value("expedition", "echo", echo)
	config.set_value("ruined_world", "progress", ruins)
	config.set_value("mi_po", "progress", mi_po)
	config.set_value("tidal_blindspot", "progress", voyage)
	config.set_value("star_ring_gala", "progress", gala)
	config.set_value("luo_story", "progress", luo_story)
	config.set_value("pirate_arc", "progress", pirate_arc)
	for field: String in SAVE_FIELDS:
		config.set_value("progress", field, get(field))
	last_save_error = config.save(save_path + ".pending")
	if last_save_error == OK and needs_v1_backup and FileAccess.file_exists(save_path) and not FileAccess.file_exists(save_path + ".v1-backup"):
		last_save_error = DirAccess.copy_absolute(ProjectSettings.globalize_path(save_path), ProjectSettings.globalize_path(save_path + ".v1-backup"))
	if last_save_error == OK:
		last_save_error = DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path + ".pending"), ProjectSettings.globalize_path(save_path))
		if last_save_error == OK:
			needs_v1_backup = false
	return last_save_error


func load_progress() -> bool:
	var config := ConfigFile.new()
	if config.load(save_path) != OK or config.get_value("meta", "version", 0) not in [1, 2, 3, 4, 5]:
		return false
	var version: int = config.get_value("meta", "version")
	var next_luo: Variant = config.get_value("luo_story", "progress", LUO_STORY_DEFAULTS.duplicate(true))
	if not next_luo is Dictionary:
		return false
	for key: String in LUO_STORY_DEFAULTS:
		if not next_luo.has(key) or typeof(next_luo[key]) != typeof(LUO_STORY_DEFAULTS[key]):
			return false
	if next_luo.stage not in range(7) or next_luo.intimacy not in ["none", "refused", "embrace", "kiss"] or next_luo.disposition not in ["none", "submitted"]:
		return false
	if (next_luo.stage < 2 and next_luo.intimacy != "none") or (next_luo.stage >= 2 and next_luo.intimacy == "none") or (next_luo.stage == 6) != (next_luo.disposition == "submitted"):
		return false
	var next_echo: Dictionary = ECHO_DEFAULTS.duplicate(true)
	if version >= 2:
		var candidate: Variant = config.get_value("expedition", "echo", null)
		if not candidate is Dictionary:
			return false
		for key: String in ECHO_DEFAULTS:
			if not candidate.has(key) or typeof(candidate[key]) != typeof(ECHO_DEFAULTS[key]):
				return false
		if candidate.entry not in ["", "combat", "maintenance", "permit"] or candidate.outcome not in ["", "keep", "shutdown"]:
			return false
		for clue: Variant in candidate.clues:
			if clue not in ["highland", "wrecksite", "ravine"] or candidate.clues.count(clue) != 1:
				return false
		for place: Variant in candidate.visited:
			if place not in ECHO_LOCATIONS:
				return false
		next_echo = candidate.duplicate(true)
	var next_ruins: Variant = config.get_value("ruined_world", "progress", RUINS_DEFAULTS.duplicate(true))
	if not next_ruins is Dictionary:
		return false
	for key: String in RUINS_DEFAULTS:
		if not next_ruins.has(key) or typeof(next_ruins[key]) != typeof(RUINS_DEFAULTS[key]):
			return false
	for clue: Variant in next_ruins.clues:
		if clue not in ["crater", "memorial", "observatory"] or next_ruins.clues.count(clue) != 1:
			return false
	for place: Variant in next_ruins.visited:
		if place not in RUIN_LOCATIONS:
			return false
	if next_ruins.secret_recovered and (not next_ruins.shelter_secured or next_ruins.clues.size() < 2):
		return false
	if next_ruins.reported and not next_ruins.secret_recovered:
		return false
	if not next_ruins.accepted and (not next_ruins.visited.is_empty() or next_ruins.shelter_secured or not next_ruins.clues.is_empty() or next_ruins.secret_recovered or next_ruins.reported):
		return false
	if next_ruins.accepted and not next_echo.reward_claimed:
		return false
	var next_mi_po: Dictionary = MI_PO_DEFAULTS.duplicate(true)
	if version >= 5:
		var mi_po_candidate: Variant = config.get_value("mi_po", "progress", null)
		if not mi_po_candidate is Dictionary:
			return false
		for key: String in MI_PO_DEFAULTS:
			if not mi_po_candidate.has(key) or typeof(mi_po_candidate[key]) != typeof(MI_PO_DEFAULTS[key]):
				return false
		for node_id: Variant in mi_po_candidate.resonance_nodes:
			if node_id not in ["crater", "observatory", "vault"] or mi_po_candidate.resonance_nodes[node_id] not in ["positive", "inverse", "silent"]:
				return false
		if mi_po_candidate.trust not in [0, 30, 80]:
			return false
		var checks_complete: bool = mi_po_candidate.clock_restored and mi_po_candidate.pulse_verified and mi_po_candidate.memorial_returned
		if (mi_po_candidate.trust >= 30 or mi_po_candidate.joined) and not checks_complete:
			return false
		if mi_po_candidate.memorial_returned and not mi_po_candidate.nameplates_placed:
			return false
		if (mi_po_candidate.nameplates_taken or mi_po_candidate.nameplates_placed or checks_complete) and not mi_po_candidate.met:
			return false
		if mi_po_candidate.trust == 80 and (not mi_po_candidate.archive_recovered or not mi_po_candidate.shared_custody or not mi_po_candidate.civilian_archive_first):
			return false
		if mi_po_candidate.archive_recovered and mi_po_candidate.resonance_nodes.size() != 3:
			return false
		if mi_po_candidate.module_claimed and (not mi_po_candidate.archive_recovered or mi_po_candidate.civilian_archive_first):
			return false
		if mi_po_candidate.quest_complete != mi_po_candidate.reward_claimed or (mi_po_candidate.quest_complete and not mi_po_candidate.archive_recovered):
			return false
		next_mi_po = mi_po_candidate.duplicate(true)
	var next_voyage: Dictionary = VOYAGE_DEFAULTS.duplicate(true)
	if version >= 3:
		var voyage_candidate: Variant = config.get_value("tidal_blindspot", "progress", null)
		if not voyage_candidate is Dictionary:
			return false
		for key: String in VOYAGE_DEFAULTS:
			if not voyage_candidate.has(key) or typeof(voyage_candidate[key]) != typeof(VOYAGE_DEFAULTS[key]):
				return false
		if voyage_candidate.module_choice not in ["", "insulation", "battery"] or voyage_candidate.sprays < 0 or voyage_candidate.sprays > 3:
			return false
		for place: Variant in voyage_candidate.visited:
			if place not in VOYAGE_LOCATIONS or voyage_candidate.visited.count(place) != 1:
				return false
		for defeated_id: Variant in voyage_candidate.defeated:
			if not str(defeated_id).begins_with("voyage_") or voyage_candidate.defeated.count(defeated_id) != 1:
				return false
		if voyage_candidate.accepted and not next_echo.reward_claimed:
			return false
		next_voyage = voyage_candidate.duplicate(true)
	var next_gala: Dictionary = GALA_DEFAULTS.duplicate(true)
	if version >= 4:
		var gala_candidate: Variant = config.get_value("star_ring_gala", "progress", null)
		if not gala_candidate is Dictionary:
			return false
		for key: String in GALA_DEFAULTS:
			if not gala_candidate.has(key) or typeof(gala_candidate[key]) != typeof(GALA_DEFAULTS[key]):
				return false
		if gala_candidate.outfit not in ["evening", "dancer"] or gala_candidate.influence < 0 or gala_candidate.influence > 3:
			return false
		next_gala = gala_candidate.duplicate(true)
	var next_pirate: Variant = config.get_value("pirate_arc", "progress", PIRATE_ARC_DEFAULTS.duplicate(true))
	if not next_pirate is Dictionary:
		return false
	for key: String in PIRATE_ARC_DEFAULTS:
		if not next_pirate.has(key):
			next_pirate[key] = PIRATE_ARC_DEFAULTS[key]
	for key: String in PIRATE_ARC_DEFAULTS:
		if not next_pirate.has(key) or typeof(next_pirate[key]) != typeof(PIRATE_ARC_DEFAULTS[key]):
			return false
	if next_pirate.gamble_round not in range(4) or next_pirate.gamble_result not in ["", "lost_first", "won_second", "cleared"]:
		return false
	if next_pirate.mirror_anchor_step not in range(4):
		return false
	if next_pirate.boarding_stage not in range(3):
		return false
	if next_pirate.qiu_arrested and next_pirate.gamble_result != "cleared":
		return false
	if next_pirate.returned_base and not next_pirate.qiu_arrested:
		return false
	if (next_pirate.mirror_cleared or next_pirate.wen_located) and not next_pirate.returned_base:
		return false
	if next_pirate.wen_defeated and (not next_pirate.wen_located or next_pirate.boarding_stage != 2):
		return false
	if next_pirate.wen_failures < 0 or (next_pirate.wen_failures > 0 and (not next_pirate.wen_located or next_pirate.boarding_stage != 2)):
		return false
	if next_pirate.finale_calibration not in range(4):
		return false
	if (next_pirate.finale_unlocked or next_pirate.finale_started or next_pirate.yue_defeated or next_pirate.true_end_seen) and not next_pirate.wen_defeated:
		return false
	if next_pirate.finale_started and not next_pirate.finale_unlocked:
		return false
	if next_pirate.finale_calibration > 0 and not next_pirate.finale_started:
		return false
	if (next_pirate.yue_defeated or next_pirate.true_end_seen) and next_pirate.finale_calibration != 3:
		return false
	var data: Dictionary = {}
	for field: String in SAVE_FIELDS:
		if not config.has_section_key("progress", field) or typeof(config.get_value("progress", field)) != typeof(get(field)):
			return false
		data[field] = config.get_value("progress", field)
	if data.max_health <= 0 or data.max_energy <= 0 or data.health <= 0 or data.health > data.max_health or data.energy < 0 or data.energy > data.max_energy or data.credits < 0 or data.experience < 0:
		return false
	if data.quest_state not in range(QuestState.COMPLETE + 1) or data.quest_state == QuestState.BATTLE_IN_PROGRESS or data.saved_location not in ["command", "b7", "finale"] + ECHO_LOCATIONS + RUIN_LOCATIONS + VOYAGE_LOCATIONS:
		return false
	if data.saved_location in ECHO_LOCATIONS and (not next_echo.accepted or data.quest_state != QuestState.COMPLETE):
		return false
	if data.saved_location in RUIN_LOCATIONS and (not next_ruins.accepted or data.quest_state != QuestState.COMPLETE):
		return false
	if data.saved_location in VOYAGE_LOCATIONS and (not next_voyage.accepted or data.quest_state != QuestState.COMPLETE):
		return false
	if data.saved_location == "finale" and (not next_pirate.finale_started or data.quest_state != QuestState.COMPLETE):
		return false
	if data.supply_choice not in range(3) or data.relay_choice not in range(3) or data.record_recovered not in range(3):
		return false
	if data.equipped_armor not in data.owned_armors or "heavy" not in data.owned_armors or data.owned_armors.size() > 3:
		return false
	for armor: Variant in data.owned_armors:
		if not ARMOR_NAMES.has(armor):
			return false
	for item: String in ITEM_NAMES:
		if not data.inventory.has(item) or typeof(data.inventory[item]) != TYPE_INT or data.inventory[item] < 0 or data.inventory[item] > 9:
			return false
	if data.gift_status not in ["new", "declined", "accepted", "returned"] or data.battery_gift_status not in ["new", "accepted", "refused"] or data.invitation not in ["none", "refused", "public", "private", "ended"]:
		return false
	for field: String in SAVE_FIELDS:
		if field == "owned_armors":
			owned_armors.assign(data[field])
		else:
			set(field, data[field])
	battle_active = false
	echo = next_echo
	ruins = next_ruins.duplicate(true)
	mi_po = next_mi_po.duplicate(true)
	voyage = next_voyage.duplicate(true)
	gala = next_gala.duplicate(true)
	luo_story = next_luo.duplicate(true)
	pirate_arc = next_pirate.duplicate(true)
	needs_v1_backup = version == 1
	persistence_enabled = true
	return true


func armor_stage() -> int:
	var ratio := float(health) / max_health
	return 2 if ratio < 0.25 else (1 if ratio < 0.50 else 0)


func stage_name() -> String:
	return ["正常", "一阶段破损", "二阶段破损"][armor_stage()] if health > 0 else "失去战斗能力"


func attack_multiplier(boosted: bool = false, counter: bool = false) -> float:
	if health <= 0:
		return 0.0
	var multiplier := 1.0 + 0.4 * (1.0 - clampf(float(health) / max_health, 0.0, 1.0))
	if boosted and equipped_armor == "redline":
		multiplier *= 3.0
	if counter:
		multiplier *= 1.75
	return minf(multiplier, 4.0)


func incoming_multiplier() -> float:
	var outfit := 2.0 if equipped_armor == "redline" else (0.9 if equipped_armor == "composite" else 1.0)
	return [1.0, 1.15, 1.35][armor_stage()] * outfit


func speed_multiplier() -> float:
	return [1.0, 1.15, 1.30][armor_stage()] * (0.95 if equipped_armor == "composite" else 1.0)


func equip_armor(armor: String) -> bool:
	if battle_active or armor not in owned_armors:
		return false
	equipped_armor = armor
	return true


func add_item(item: String, amount: int = 1) -> bool:
	if not inventory.has(item) or amount <= 0 or int(inventory[item]) + amount > 9:
		return false
	inventory[item] += amount
	return true


func use_item(item: String) -> bool:
	if health <= 0 or not inventory.has(item) or int(inventory[item]) <= 0:
		return false
	if item == "battery":
		if energy >= max_energy:
			return false
		energy = mini(max_energy, energy + ceili(max_energy * 0.20))
	else:
		if health >= max_health:
			return false
		health = mini(max_health, health + ceili(max_health * (0.45 if item == "repair_pack" else 0.25)))
	inventory[item] -= 1
	return true


func buy_item(item: String) -> bool:
	var price: int = 60 if item == "battery" else 50
	if battle_active or item not in ["battery", "med_gel"] or credits < price or not add_item(item):
		return false
	credits -= price
	return true


func accept_redline() -> bool:
	if contact_ended or gift_status not in ["new", "declined"]:
		return false
	gift_status = "accepted"
	owned_armors.append("redline")
	return true


func accept_batteries() -> bool:
	if contact_ended or gift_status != "accepted" or not redline_used or battery_gift_status != "new":
		return false
	if not add_item("battery", 2):
		return false
	battery_gift_status = "accepted"
	route_known = true
	return true


func return_redline() -> bool:
	if battle_active or gift_status != "accepted":
		return false
	if equipped_armor == "redline":
		equipped_armor = "heavy"
	owned_armors.erase("redline")
	gift_status = "returned"
	contact_ended = true
	return true


func claim_chest() -> bool:
	if chest_claimed or not add_item("repair_pack"):
		return false
	chest_claimed = true
	evidence_found = true
	module_owned = true
	owned_armors.append("composite")
	return true


func level() -> int:
	var result := 1
	for threshold: int in LEVEL_THRESHOLDS:
		if experience >= threshold:
			result = LEVEL_THRESHOLDS.find(threshold) + 1
	return result


func experience_text() -> String:
	var current_level := level()
	if current_level == 5:
		return "LV5 MAX · EXP %d" % experience
	return "LV%d · EXP %d/%d" % [current_level, experience - LEVEL_THRESHOLDS[current_level - 1], LEVEL_THRESHOLDS[current_level] - LEVEL_THRESHOLDS[current_level - 1]]


func toggle_module() -> bool:
	if battle_active or not module_owned:
		return false
	module_equipped = not module_equipped
	max_energy += 40 if module_equipped else -40
	energy = mini(energy, max_energy)
	return true


func reset() -> void:
	echo = ECHO_DEFAULTS.duplicate(true)
	ruins = RUINS_DEFAULTS.duplicate(true)
	mi_po = MI_PO_DEFAULTS.duplicate(true)
	voyage = VOYAGE_DEFAULTS.duplicate(true)
	gala = GALA_DEFAULTS.duplicate(true)
	luo_story = LUO_STORY_DEFAULTS.duplicate(true)
	pirate_arc = PIRATE_ARC_DEFAULTS.duplicate(true)
	needs_v1_backup = false
	persistence_enabled = false
	saved_location = "command"
	last_save_error = OK
	max_health = 1000
	max_energy = 620
	next_experience = 2600
	inventory = {"med_gel": 2, "battery": 2, "repair_pack": 1}
	owned_armors = ["heavy"]
	equipped_armor = "heavy"
	battle_active = false
	gift_status = "new"
	redline_used = false
	battery_gift_status = "new"
	invitation = "none"
	contact_ended = false
	evidence_found = false
	luo_exposed = false
	chest_claimed = false
	module_owned = false
	module_equipped = false
	route_known = false
	side_patrol_defeated = false
	health = 860
	energy = 420
	credits = 480
	experience = 1840
	quest_state = QuestState.NOT_STARTED
	supply_choice = SupplyChoice.NONE
	relay_choice = RelayChoice.NONE
	record_recovered = RecordRecovered.NONE
	reward_claimed = false
	quest_log = ""


func accept_quest() -> void:
	if quest_state == QuestState.NOT_STARTED:
		quest_state = QuestState.ACCEPTED


func take_supply(choice: SupplyChoice) -> bool:
	if quest_state < QuestState.ACCEPTED or supply_choice != SupplyChoice.NONE:
		return false
	if choice == SupplyChoice.MED_GEL:
		health = mini(max_health, health + 140)
	elif choice == SupplyChoice.BATTERY:
		energy = mini(max_energy, energy + 120)
	else:
		return false
	supply_choice = choice
	return true


func spend_energy(amount: int) -> bool:
	if amount < 0 or energy < amount:
		return false
	energy -= amount
	return true


func take_damage(amount: int) -> void:
	health = maxi(0, health - maxi(0, amount))


func claim_quest_reward() -> bool:
	if quest_state != QuestState.RECORD_RECOVERED or reward_claimed:
		return false
	if record_recovered == RecordRecovered.FULL:
		grant_reward(320, 250)
		quest_log = "异常握手源头：核心区下方。"
	else:
		grant_reward(240, 200)
	reward_claimed = true
	quest_state = QuestState.COMPLETE
	return true


func grant_reward(reward_credits: int, reward_experience: int) -> void:
	var old_level := level()
	credits += reward_credits
	experience += reward_experience
	var gained := level() - old_level
	max_health += gained * 80
	health += gained * 80
	max_energy += gained * 30
	energy += gained * 30
	next_experience = LEVEL_THRESHOLDS[level()] if level() < 5 else LEVEL_THRESHOLDS[4]


func recover_after_defeat() -> void:
	health = int(round(max_health * 0.35))
