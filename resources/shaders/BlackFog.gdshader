shader_type canvas_item;


uniform vec3 black_color: source_color;
uniform sampler2D noise;
uniform sampler2D extra_noise;
uniform float time_scale = 0.01;
uniform vec2 scroll_dir = vec2(1.0, 0.0);
uniform float extra_noise_strength = 0.2;
uniform float threshold = 0.7;
uniform float power = 0.5;


float fmod(float x, float y) {
	return x - floor(x / y) * y;
}


vec2 fmod(vec2 x, float y) {
	return vec2(fmod(x[0], y), fmod(x[1], y));
}


vec3 lerp(vec3 x, vec3 y, float w) {
	return x + (y - x) * w;
}


void fragment() {
	vec2 uv = fmod(UV + scroll_dir * TIME * time_scale, 1.0);
	vec2 extra_uv = fmod(UV - scroll_dir * TIME * time_scale, 1.0);
	float v = texture(noise, uv).r + texture(extra_noise, extra_uv).r * extra_noise_strength;

	if (v > threshold) COLOR = vec4(vec3(1.0), COLOR.a);
	else COLOR = vec4(black_color, pow(UV.y, 0.2) * COLOR.a);
	
	float a = pow(UV.y, power) * COLOR.a;
	COLOR = vec4(lerp(vec3(1.0), black_color, (1.0 - v) * a), a);
}