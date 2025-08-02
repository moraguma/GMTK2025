shader_type canvas_item;


const float TWO_PI = 6.28;


uniform float wind_center = 1.0;
uniform float wind_amplitude = 0.5;
uniform float wind_frequency = 0.5;


uniform float wind_strenght: hint_range(1.0, 32.0, 1.0);
uniform float invert_y: hint_range(0.0, 1.0, 1.0) = 1.0;


void vertex() {
	float y = invert_y - UV.y;
	float regulator = (invert_y - 0.5) * 2.0;
	float x_movement = regulator * (wind_center - wind_amplitude * sin(TWO_PI * wind_frequency * TIME)) * y * wind_strenght;

	VERTEX.x += x_movement;

	float y_vertex = y * TEXTURE_PIXEL_SIZE[1];
	float x_vertex = x_movement * TEXTURE_PIXEL_SIZE[0];
	VERTEX.y += regulator * (sqrt(abs(y_vertex * y_vertex - x_vertex * x_vertex)) + y_vertex);
}