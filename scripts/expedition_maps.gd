extends RefCounted

const SIZE := Vector2(1536, 1024)
const NAMES := {"hangar": "H1 · 游隼飞船舱", "ballroom": "H1 · 星环舞厅", "landing": "灰潮盆地 · 着陆点", "highland": "断讯高地", "wrecksite": "坠毁货船", "ravine": "裂隙栈道", "station": "废弃观测站", "archive": "观测站 · 档案室", "ruined_village": "阿斯佩拉 · 余烬村", "ruin_vault": "阿斯佩拉 · 星核祭库", "starport": "H1 星港 · 候机环", "tentacle_field": "涅柔斯-4 · 潮根滩涂", "eldritch_ruins": "涅柔斯-4 · 沉眠者回廊", "storm_sea": "涅柔斯-4 · 裂潮海"}
const IMAGES := {"hangar": "echo-hangar-v1.png", "ballroom": "star-ring-ballroom-v1.png", "landing": "echo-landing-v1.png", "highland": "echo-highland-v1.png", "wrecksite": "echo-wreck-v1.png", "ravine": "echo-ravine-v1.png", "station": "echo-station-v1.png", "archive": "echo-archive-v1.png", "ruined_village": "aspera-ember-village-map-v1.png", "ruin_vault": "aspera-resonance-archive-map-v1.png", "starport": "voyage-starport-v1.png", "tentacle_field": "voyage-tentacle-field-v1.png", "eldritch_ruins": "voyage-eldritch-ruins-v1.png", "storm_sea": "voyage-storm-sea-v1.png"}
const LINKS := {"hangar": ["ballroom"], "ballroom": ["hangar"], "landing": ["highland", "wrecksite", "ravine"], "highland": ["landing", "wrecksite", "station"], "wrecksite": ["landing", "highland", "ravine", "station"], "ravine": ["landing", "wrecksite", "station"], "station": ["highland", "wrecksite", "ravine"], "archive": ["station"], "ruined_village": ["ruin_vault"], "ruin_vault": ["ruined_village"], "starport": [], "tentacle_field": ["eldritch_ruins"], "eldritch_ruins": ["tentacle_field", "storm_sea"], "storm_sea": ["eldritch_ruins"]}
const SPAWNS := {"hangar": Vector2(560, 740), "ballroom": Vector2(770, 865), "landing": Vector2(680, 620), "highland": Vector2(820, 810), "wrecksite": Vector2(780, 660), "ravine": Vector2(1000, 760), "station": Vector2(790, 750), "archive": Vector2(770, 750), "ruined_village": Vector2(520, 780), "ruin_vault": Vector2(770, 750), "starport": Vector2(760, 850), "tentacle_field": Vector2(730, 850), "eldritch_ruins": Vector2(760, 850), "storm_sea": Vector2(760, 790)}
const OBSTACLES := {
	"hangar": [Rect2(470, 65, 650, 350), Rect2(55, 505, 255, 310), Rect2(1245, 355, 190, 160), Rect2(1220, 660, 205, 175)],
	"ballroom": [Rect2(525, 60, 490, 240), Rect2(60, 190, 260, 220), Rect2(1215, 190, 260, 220), Rect2(70, 700, 300, 220), Rect2(1165, 700, 300, 220)],
	"landing": [Rect2(260, 145, 235, 235), Rect2(935, 40, 420, 270), Rect2(64, 380, 155, 130), Rect2(75, 770, 200, 190), Rect2(1280, 760, 180, 200)],
	"highland": [Rect2(250, 45, 280, 295), Rect2(470, 395, 85, 95), Rect2(985, 70, 300, 330), Rect2(220, 710, 335, 255)],
	"wrecksite": [Rect2(105, 115, 115, 230), Rect2(220, 60, 340, 85), Rect2(580, 160, 105, 110), Rect2(1100, 115, 190, 125), Rect2(165, 715, 175, 170), Rect2(1190, 700, 190, 195)],
	"ravine": [Rect2(660, 48, 225, 195), Rect2(665, 335, 235, 225), Rect2(80, 220, 85, 320), Rect2(350, 890, 230, 90)],
	"station": [Rect2(420, 40, 755, 410), Rect2(170, 660, 250, 220), Rect2(1230, 655, 190, 210)],
	"archive": [Rect2(595, 110, 345, 280), Rect2(170, 180, 335, 55), Rect2(1040, 180, 310, 70)],
	"ruined_village": [Rect2(80, 70, 250, 180), Rect2(1160, 80, 270, 180), Rect2(580, 100, 360, 170)],
	"ruin_vault": [Rect2(595, 110, 345, 280), Rect2(170, 180, 335, 55), Rect2(1040, 180, 310, 70)],
	"starport": [Rect2(70, 80, 280, 210), Rect2(1180, 80, 280, 210), Rect2(540, 80, 450, 170)],
	"tentacle_field": [Rect2(80, 100, 300, 180), Rect2(1120, 90, 310, 210), Rect2(610, 380, 310, 155)],
	"eldritch_ruins": [Rect2(80, 90, 330, 230), Rect2(1110, 80, 330, 240), Rect2(620, 130, 300, 190)],
	"storm_sea": [Rect2(70, 70, 250, 190), Rect2(1210, 70, 250, 190), Rect2(620, 100, 300, 155)],
}
