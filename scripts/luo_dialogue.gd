extends RefCounted

var world: Node
var state: ZeroDomainGameState
const CHAPTERS: Array[String] = ["善意的表象", "一次靠近", "门禁留下的影子", "恩惠不是筹码", "被安排的巧合", "收回信任"]


func _init(exploration: Node) -> void:
	world = exploration
	state = world.game_state


func open() -> void:
	if state.luo_story.stage == 6:
		_say("私人关系已经结束。证据已提交沈砚，罗茂的相关权限等待纪律审查。后勤补给仍由基地独立终端提供。")
		_option("回看支线记录", story_menu)
		_option("基地独立物资终端", world._base_shop)
		if state.gift_status == "accepted":
			_option("退还赤线（自愿）", _confirm_return)
		return
	if state.luo_story.stage >= 3:
		_say("凌霁已经备份异常访问记录。她不再回应私人赠礼，把后续交流限制在可核验的任务信息上。" if state.luo_story.stage < 5 else "完整记录证明了监视和扣留情报。凌霁保全证据，准备正式对质，不再接受罗茂的私人援助。")
		_option("查看证据与下一步", story_menu)
		_option("基地独立物资终端", world._base_shop)
		_option("划清界限 / 退还", boundaries)
		return
	if state.contact_ended:
		_say("你暂停了私人往来，但保留任务交易频道。罗茂没有再提赴约，只留下一句：‘有件东西，等你带着新线索再谈。’\n你此前的拒绝与证据仍保留；当前没有新的交换条件，也不会因此进入结局。")
		_primary_option("只谈任务情报与交易", information)
		_option("询问那件东西（后续线索）", pending_business)
		_option("基地物资终端", world._base_shop)
		if state.gift_status == "accepted":
			_option("退还已收下的赤线", _confirm_return)
		if state.evidence_found and not state.luo_exposed:
			_option("核实供货记录，保留证据", _expose)
		return
	if state.gift_status in ["new", "declined"]:
		_say("通讯另一端的罗茂还是那副和气模样，像往常一样先问她任务有没有受伤。\n“凌霁，这套‘赤线’是我托老关系留下的试制件。你在外面少遇一点危险，比压在仓库里有用。别急，先看参数。”")
		_option("先检查赤线的参数与代价", inspect_suit)
		_option("收下，但暂不穿戴", accept_gift)
		_option("拒绝礼物", decline_gift)
		_option("只谈情报和交易", information)
		return
	var relationship: String = "凌霁仍将彼此看作同事。"
	if state.luo_story.intimacy in ["embrace", "kiss"]:
		relationship = "凌霁记得那次自愿的靠近，但它不是对后续要求的承诺。"
	_say("“赤线用着还顺手吗？别为了赶任务硬撑。”罗茂没有邀功，只把几项维护数据发了过来。\n" + relationship)
	if state.redline_used and state.battery_gift_status == "new":
		_option("听听他的新赠礼", battery_offer)
	if state.redline_used and state.battery_gift_status != "new" and state.luo_story.stage < 2:
		_option("回应他的私人邀约", invitation_offer)
	_option("划清界限 / 退还 / 质问", boundaries)
	_option("情报与交易", information)
	_option("询问后续交易线索", pending_business)
	_option("赤线演示（需先在 C 面板穿戴）", world._start_optional_battle.bind("demo"))


func inspect_suit() -> void:
	_say("赤线：攻击支付额外 12 MP 可获得 ×3 增幅；过载突袭共需 72 MP。\n受到伤害 ×2，即使 MP 用尽也不会消失。残血与反击合计最高 ×4 攻击。\n装备可在战斗外随时换下。没有隐藏契约，接受后不会自动穿戴。")
	_option("收下，稍后自己决定是否穿", accept_gift)
	_option("拒绝", decline_gift)
	_option("返回", open)


func accept_gift() -> void:
	if state.luo_story.stage >= 3:
		open()
		return
	if state.accept_redline():
		_say("赤线已放入装备栏，当前装备未改变。\n“识货。下次再来，我还有好东西。”\n按 C 换装；90 HP 演示结束会恢复 HP、MP 与道具，不发放经验。")
		_option("打开人物装备", world._open_character)
		_option("结束通讯", world._close_modals)
	world._update_hud()


func decline_gift() -> void:
	state.gift_status = "declined"
	_say("凌霁：“好意心领了，我先用自己的装备。”\n罗茂点点头，没有追问，只提醒她需要时还能来找他。主线与正常补给不受影响。")
	_option("只谈情报", information)
	_option("结束通讯", world._close_modals)
	world._update_hud()


func battery_offer() -> void:
	if state.luo_story.stage >= 3:
		open()
		return
	_say("“赤线很吃电吧？这两枚电池你带着。我再告诉你一个没写进公共导航的 B7 维护入口——这是我以前跑仓储时留下的关系。”\n电池与基地标准型号相同；不是独家补给。背包上限为每种 9 个。")
	_option("接受 2 枚电池（不承诺私人往来）", _accept_batteries)
	_option("拒绝后续赠礼", _refuse_batteries)
	_option("返回", open)


func _accept_batteries() -> void:
	if state.luo_story.stage >= 3:
		open()
		return
	if state.accept_batteries():
		invitation_offer()
	else:
		_say("未领取：背包放不下两枚电池，或这份赠礼已经处理。没有吞掉奖励。")
		_option("返回", open)
	world._update_hud()


func _refuse_batteries() -> void:
	state.battery_gift_status = "refused"
	_say("凌霁：“补给我会自己买，不用继续送了。”\n罗茂收起盒子。你仍能保留已收下的赤线。")
	_option("返回", open)
	world._update_hud()


func invitation_offer() -> void:
	if state.luo_story.stage >= 2:
		story_menu()
		return
	var response_names := {"none": "尚未答复", "refused": "已拒绝", "public": "只在公共场所见面", "private": "同意见面，未承诺其他要求", "ended": "停止往来"}
	_say("罗茂犹豫了好一会儿才开口：“任务结束后，愿不愿意一起吃顿饭？不谈装备也行。”\n这是同事关系之外的邀请，不是领取装备的条件。当前回应：%s。" % response_names[state.invitation])
	_option("拒绝私人邀约，保留装备", _respond.bind("refused"))
	_option("只同意在公共休息区见面", _respond.bind("public"))
	_option("愿意赴约，但不承诺其他要求", _respond.bind("private"))
	_option("停止私人往来", _respond.bind("ended"))


func _respond(response: String) -> void:
	if state.luo_story.stage >= 6:
		open()
		return
	state.invitation = response
	if response == "ended":
		state.contact_ended = true
	var lines := {
		"refused": "凌霁：“谢谢你，但我们先做同事。”罗茂接受了答复，没有收回已经送出的装备。",
		"public": "凌霁答应在公共休息区吃顿便饭。罗茂明显高兴起来，却没有擅自改变约定。",
		"private": "凌霁同意任务结束后单独见面。罗茂告诉她，自己手里还有一段从未上报的旧仓储记录；他愿意先把秘密交给她，再由她决定是否继续了解。",
		"ended": "你关闭私人邀约频道，但保留任务交易渠道。拒绝本次要求不等于结束这条支线。",
	}
	_say(lines[response])
	if response == "private":
		_option("先问清物品与交易条件", pending_business)
		_option("现在离开，取消会面", _respond.bind("refused"))
	else:
		_option("结束通讯", world._close_modals)
	world._update_hud()


func pending_business() -> void:
	story_menu()


func boundaries() -> void:
	if state.luo_story.stage == 6:
		open()
		return
	_say("你可以保留已经收到的礼物而拒绝要求，也能主动退还赤线。\n退还会自动换回制式重甲，暂停私人往来，但任务交易渠道仍保留；不会拿走其他道具。")
	_option("保留装备，但只做普通交易", _respond.bind("ended"))
	if state.gift_status == "accepted":
		_option("我要退还赤线（下一步确认）", _confirm_return)
	if state.evidence_found:
		_option("拿出供货记录，要求解释（不结束支线）", _expose)
	_option("返回", open)


func _confirm_return() -> void:
	_say("确认退还赤线？服装将从装备栏移除，不能再次索取。当前穿着赤线时会换回重甲。")
	_option("确认退还，保留任务交易渠道", _return_suit)
	_option("取消", boundaries)


func _return_suit() -> void:
	state.return_redline()
	world._update_hud()
	open()


func _expose() -> void:
	if state.luo_story.stage >= 3:
		story_menu()
		return
	if not state.evidence_found:
		return
	state.luo_exposed = true
	_say("凌霁把备份记录放到通讯屏前：“这批试制件没有走公库。你到底替谁担保？”\n罗茂没有发火，只承认自己动用了旧关系：“我想让你安全回来，这是真的。其他事情，等你愿意听时我会说。”\n你保留记录，决定暂不追问；任务交易仍可继续，这还不是最终决裂。")
	_option("暂存疑点，询问后续线索", pending_business)
	_option("结束通讯", world._close_modals)
	world._update_hud()


func information() -> void:
	_say("“B7 有条废弃维护支路，里面可能还留着装备箱。我能替你查到旧坐标，但现场警戒已经不在后勤记录里。”\n你可以花 80 CR 请他联络旧管理员，也能自行寻找。基地商店与他的赠礼无关。")
	if not state.route_known:
		_option("购买支路坐标 · 80 CR（非必需）", _buy_route)
	_option("基地独立物资终端", world._base_shop)
	_option("结束通讯", world._close_modals)


func _buy_route() -> void:
	if not state.route_known and state.credits >= 80:
		state.credits -= 80
		state.route_known = true
		_say("坐标：B7 南侧的维护支路终端。请先核验警报；情报并未承诺没有敌人。")
	else:
		_say("未扣款：信用点不足，或已经获得坐标。")
	world._update_hud()
	_option("结束通讯", world._close_modals)


func _say(line: String) -> void:
	world._show_dialogue("后勤私人通讯 / LUO", "罗茂 · 罗老板", line)
	_option("支线剧情 / 已见记录", story_menu)


func _option(title: String, callback: Callable) -> void:
	world._add_dialogue_choice(title, callback)


func _primary_option(title: String, callback: Callable) -> void:
	world._add_dialogue_choice(title, callback)
	var choices: VBoxContainer = world.dialogue_choices
	choices.move_child(choices.get_child(choices.get_child_count() - 1), 0)


func story_menu() -> void:
	var stage: int = state.luo_story.stage
	world._show_dialogue("罗茂支线 / 私人关系与证据", "支线记录", "已完成 %d / 6 段。现场剧情须返回基地；回看不会改变选择、发放道具或推进状态。\n拒绝接触或暂停往来，都不妨碍调查。" % stage)
	if stage < CHAPTERS.size():
		if _chapter_available(stage):
			_option("继续 · " + CHAPTERS[stage], _chapter.bind(stage, false))
		else:
			var requirements: Array[String] = ["返回基地", "完成静默回路并汇报", "接受回声之外任务", "取得任意两份冰原线索", "处理 ECHO-9 信标", "返回沈砚处汇报回声之外"]
			_option("待解锁 · " + requirements[stage] + "，并返回基地", story_menu)
	for chapter: int in range(stage):
		_option("回看 · " + CHAPTERS[chapter], _chapter.bind(chapter, true))
	_option("离开记录", world._close_modals)


func progress_summary() -> String:
	var stage: int = state.luo_story.stage
	if stage == 6:
		return "6/6 · 证据已提交沈砚，私人关系结束。\n可回看记录；基地独立补给不受影响。"
	var targets: Array[String] = ["返回基地，查看后勤会面", "完成静默回路并向沈砚汇报", "接受回声之外，核对基地门禁", "取得任意两份冰原线索，再返回基地", "处理 ECHO-9 信标，再核对完整日志", "汇报回声之外，再与罗茂对质"]
	return "%d/6 · %s\n下一步：%s。\n拒绝私人往来不阻断证据调查。" % [stage, CHAPTERS[stage], "在基地支线通讯中继续本段" if _chapter_available(stage) else targets[stage]]


func _chapter_available(chapter: int) -> bool:
	if state.saved_location != "command":
		return false
	match chapter:
		0: return true
		1: return state.quest_state == ZeroDomainGameState.QuestState.COMPLETE
		2: return state.echo.accepted
		3: return state.echo.clues.size() >= 2
		4: return state.echo.outcome != ""
		5: return state.echo.reward_claimed
	return false


func _chapter(chapter: int, replay: bool) -> void:
	if chapter < 0 or chapter >= CHAPTERS.size():
		return
	if replay:
		if chapter >= int(state.luo_story.stage):
			return
	elif chapter != int(state.luo_story.stage) or not _chapter_available(chapter):
		story_menu()
		return
	var lines: Array[String] = [
		"后勤台前，罗茂把试制装备箱推向凌霁，又停下手，让她自己决定是否接过。\n“先看参数，别急着答应。我只盼着你平安回来。”\n凌霁只把他当成热心同事。赠礼仍按原有装备菜单领取，观看此段不发放额外物品。",
		"B7 任务结束，罗茂约凌霁在公共休息区谈谈。他交出一份旧运输记录：“这事我没告诉其他人。我相信你。”\n凌霁以为他毫无保留。是否接受靠近，由她明确决定。",
		"基地门禁审计发来异常提示：后勤账号查询了凌霁的非公开训练排程，观察区在训练时被远程开启。\n凌霁当时并不知道有人观看。私人舱室还有一条无预约进入记录，备注只有‘送补给’。\n她备份摘要。一次维护误差，解释不了这些重复访问。",
		"“我替你想了这么多，你就不能再信我一次吗？”罗茂提起自己的渠道，试图用下一份情报交换更进一步的身体亲密。\n凌霁退开一步：“装备和情报都不能替我答应。没有我的同意，不要靠近。”\n罗茂收起笑容，又说她误会了。凌霁没有接受交换，决定继续核查。",
		"隔离的 ECHO 记录补全了时间戳：罗茂先扣下危险路线告警，再在出发前以私人消息送来‘救命提醒’；所谓偶遇与及时帮助都有排程查询在先。\n门禁、观察区和删改记录彼此对应。他不是偶然越界，而是刻意让她觉得只有他最可靠。\n凌霁将证据从个人通讯中隔离，准备交给沈砚。",
		"罗茂辩称：“我做这些都是为了你，我又没有真正伤害你。”\n凌霁短暂想起那些看似体贴的帮助，随后把终端放到他面前：“我以为你是在帮我。原来你只是在计算，要付出多少东西，才能把我变成你的。”\n她后退，结束私人往来。过去的信任不是允许监视和接触的通行证。",
	]
	if chapter == 1 and (state.contact_ended or replay):
		lines[1] += "\n" + _intimacy_line("refused" if state.contact_ended and not replay else str(state.luo_story.intimacy))
	if chapter == 3 and state.gift_status in ["accepted", "returned"]:
		lines[3] += "\n“那套赤线和电池……”他刚想列出人情，凌霁便打断：‘赠礼不是债。’" if state.battery_gift_status == "accepted" else "\n他又提起赤线。凌霁打断他：‘赠礼不是债。’"
	if chapter == 5 and state.luo_story.intimacy == "kiss":
		lines[5] += "\n“我相信过你，也吻过你。但那不是你继续进入我生活、碰我的身体的许可。”"
	world._show_dialogue("罗茂支线 · %d/6 · %s" % [chapter + 1, CHAPTERS[chapter]], "凌霁 / 现场记录", lines[chapter])
	world._show_luo_story_picture(chapter, str(state.luo_story.intimacy) if replay else "none")
	if replay:
		_option("返回已见记录", story_menu)
	elif chapter == 1 and not state.contact_ended:
		_option("只做同事，保持距离", _choose_intimacy.bind("refused"))
		_option("我愿意接受这一次拥抱", _choose_intimacy.bind("embrace"))
		_option("我愿意接受这一次轻吻与拥抱", _choose_intimacy.bind("kiss"))
	elif chapter == 3:
		_option("明确拒绝，保留调查记录", _finish_chapter.bind(chapter, "none"))
		_option("结束谈话，交叉核查访问记录", _finish_chapter.bind(chapter, "none"))
	else:
		_option("提交证据并结束私人关系" if chapter == 5 else "记下此事，继续自己的任务", _finish_chapter.bind(chapter, "refused" if chapter == 1 else "none"))
	_option("暂时离开（本段未确认则不推进）" if not replay else "退出回看", world._close_modals)


func _intimacy_line(choice: String) -> String:
	match choice:
		"embrace": return "凌霁明确答应这一次拥抱，两人短暂靠近后分开。她相信这是相互尊重，不是交换。"
		"kiss": return "凌霁明确答应。短暂轻吻与拥抱后，她退回自己的位置。这只是当下的选择，不是对未来的承诺。"
	return "凌霁保持同事距离。她不欠任何亲密回应；罗茂脸上仍维持着和气的笑。"


func _choose_intimacy(choice: String) -> void:
	if choice not in ["refused", "embrace", "kiss"] or state.luo_story.stage != 1 or not _chapter_available(1) or state.contact_ended:
		return
	world._show_dialogue("一次靠近 / 明确选择", "凌霁", _intimacy_line(choice))
	world._show_luo_story_picture(1, choice)
	# Commit the explicit choice once; replay never enters this callback.
	state.luo_story.intimacy = choice
	state.luo_story.stage = 2
	world._update_hud()
	state.save_progress()
	_option("返回支线记录", story_menu)
	_option("结束休息，离开", world._close_modals)


func _finish_chapter(chapter: int, intimacy: String) -> void:
	if state.luo_story.stage != chapter or not _chapter_available(chapter):
		return
	if chapter == 1:
		state.luo_story.intimacy = intimacy
	state.luo_story.stage = chapter + 1
	if chapter == 5:
		state.luo_story.disposition = "submitted"
		state.contact_ended = true
		state.invitation = "ended"
		state.luo_exposed = true
		state.quest_log += "\n罗茂支线：权限滥用与扣留情报证据已提交沈砚；私人关系结束，装备归属不变。"
	world._update_hud()
	state.save_progress()
	story_menu()
