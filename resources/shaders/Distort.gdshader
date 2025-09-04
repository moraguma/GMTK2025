shader_type canvas_item;
render_mode blend_mix;

global uniform vec4 ground_from;
global uniform vec4 ground_to;
global uniform vec4 detail_from;
global uniform vec4 detail_to;
global uniform vec4 bg_from;
global uniform vec4 bg_to;

uniform int type;

uniform sampler2D noise;
uniform float amplitude_x = 16.0;
uniform float amplitude_y = 8.0;
uniform float time_scale = 1.0;


float fmod(float x, float y) {
	return x - floor(x / y) * y;
}


vec2 fmod(vec2 x, float y) {
	return vec2(fmod(x[0], y), fmod(x[1], y));
}


void vertex() {
	float x = 0.29810501238961;
	float vidx = fmod(float(VERTEX_ID), x) / x;
	
	VERTEX[0] += texture(noise, vec2(vidx) + vec2(1, 0) * TIME * time_scale).r * amplitude_x * cos(vidx * 2.0 * PI + TIME * time_scale);
	VERTEX[1] += texture(noise, vec2(vidx) + vec2(0, 1) * TIME * time_scale).r * amplitude_y * sin(vidx * 2.0 * PI + TIME * time_scale);
}


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
	
	if (COLOR.a > 0.0 && type < 3) COLOR = lerp_color(from, to, (COLOR[0] + COLOR[1] + COLOR[2]) / 3.0);
}