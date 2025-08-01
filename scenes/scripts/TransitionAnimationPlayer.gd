extends AnimationPlayer
class_name TransitionAnimationPlayer


@export var no_transition: Dictionary
@export var never_transition: Array


func transition_anim(anim_name):
	if current_animation in never_transition or (current_animation in no_transition and anim_name in no_transition[current_animation]):
		return
	play(anim_name)
