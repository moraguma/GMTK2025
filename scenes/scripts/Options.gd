extends Control
class_name Options


signal closed_menu


@export var include_back_to_title: bool = false


var active: bool = false


@onready var options: OptionsMenu = $Base/OptionsMenu


func _ready() -> void:
	if not include_back_to_title:
		$Base/OptionsMenu/ScrollContainer/VBoxContainer/BackToTitle.free()
	options.initialize()


func activate():
	options.activate()
	
	get_tree().paused = true
	show()
	
	active = true


func _physics_process(delta: float) -> void:
	if active and (Input.is_action_just_pressed("menu") or Input.is_action_just_pressed("back")):
		active = false
		get_tree().paused = false
		hide()
		
		closed_menu.emit()
