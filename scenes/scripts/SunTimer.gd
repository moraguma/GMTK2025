extends Node2D
class_name SunTimer


const MIN_SUN_ROT = -PI / 2.0
const MAX_SUN_ROT = PI / 2.0
const STRESS_TIME = 10.0


@export var gradient: Gradient


@onready var sun_pivot: Node2D = $SunPivot
@onready var sun: ColorRect = $SunPivot/Sun
@onready var time_label: Label = $TimeLeft


var elapsed_time = 0


func _process(delta: float) -> void:
	elapsed_time += delta
	#set_time(30.0, 30.0-elapsed_time, 20.0)


func set_time(total_real_time: float, real_time_left: float, total_fake_time: float):
	var time_progress = pow((total_real_time - real_time_left) / total_real_time, 0.9)
	var fake_time_left = max(0, total_fake_time - time_progress * total_fake_time)
	if fake_time_left > STRESS_TIME:
		time_label.text = "%ds" % [int(fake_time_left)]
	else:
		time_label.text = "%.2fs" % [fake_time_left]
	
	sun_pivot.rotation = lerp(MIN_SUN_ROT, MAX_SUN_ROT, time_progress)
	sun.color = gradient.sample(time_progress)
