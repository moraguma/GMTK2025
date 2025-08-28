extends Node


const APP_ID = 3971000


@export var steam_on: bool = true


@onready var steamworks: Steamworks = Steamworks.new() if steam_on else null


func _process(delta: float) -> void:
	if steamworks:
		steamworks.run_callbacks()
