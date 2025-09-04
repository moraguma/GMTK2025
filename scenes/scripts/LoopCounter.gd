extends RichTextLabel


@export var leaderboard = "Reach Olympus"


func _ready() -> void:
	text = "[center]Finished in [wave]" + str(Globals.loop_count + 1) + " loop" + ("s" if Globals.loop_count > 0 else "") + "[/wave] - Time: [wave]%.2fs" % [Globals.last_times["Reach Olympus"]]
