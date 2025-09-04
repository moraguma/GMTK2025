extends Panel
class_name LeaderboardPosition


@export var player_color: Color


@onready var pos_label: Label = $Position
@onready var name_label: Label = $Name
@onready var score_label: Label = $Score
@onready var get_name_timer: Timer = $GetNameTimer


var id = -1


func initialize(pos: int, user_name: String, user_id: int, score: int, is_self: bool) -> void:
	get_name_timer.timeout.connect(
		func():
			var n = SteamInterface.get_player_name(user_id)
			if n == "???":
				get_name_timer.start(1.0)
			else:
				name_label.text = n
	)
	
	id = user_id
	if user_name == "???":
		get_name_timer.start(1.0)
	
	pos_label.text = "#" + str(pos)
	name_label.text = user_name
	score_label.text = "%.2fs" % [score / 1000.0]
	
	if is_self:
		for label: Label in [pos_label, name_label, score_label]:
			label.add_theme_color_override("font_color", player_color)
