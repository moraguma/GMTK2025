extends RichTextLabel


func _ready() -> void:
	text = "[center]Finished in [wave]" + str(Globals.loop_count + 1) + " loop" + ("s" if Globals.loop_count > 0 else "") + "[/wave] - Best time: [wave]%.2f" % [Globals.best_time]
