shader_type canvas_item;

global uniform vec4 ground_from;
global uniform vec4 ground_to;
global uniform vec4 detail_from;
global uniform vec4 detail_to;
global uniform vec4 bg_from;
global uniform vec4 bg_to;

uniform int type : hint_range(0, 2, 1);


vec4 lerp_color(vec4 from, vec4 to, float weight) {
	return vec4(from[0] + (to[0] - from[0]) * weight, from[1] + (to[1] - from[1]) * weight, from[2] + (to[2] - from[2]) * weight, from[3] + (to[3] - from[3]) * weight);
}


void fragment() {
	vec4 from;
	vec4 to;
	if (type == 0) {
		from = ground_from;
		to = ground_to;
	} else if (type == 1) {
		from = detail_from;
		to = detail_to;
	} else {
		from = bg_from;
		to = bg_to;
	}
	
	if (COLOR.a > 0.0) COLOR = lerp_color(from, to, (COLOR[0] + COLOR[1] + COLOR[2]) / 3.0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
