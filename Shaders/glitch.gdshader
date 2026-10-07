shader_type canvas_item;

// Desorden visual barato: franjas horizontales que se corren al azar cada
// tanto, más una leve separación de canales RGB (aberración cromática).
// Sin texturas ni assets extra, todo generado por código.

uniform float intensity : hint_range(0.0, 1.0) = 0.5;
uniform float speed : hint_range(0.1, 10.0) = 5.0;

float rand(float n) {
	return fract(sin(n) * 43758.5453123);
}

void fragment() {
	float t = TIME * speed;
	float block = floor(UV.y * 12.0);
	float shift = (rand(block + floor(t * 6.0)) - 0.5) * intensity * 0.15;

	vec2 uv_r = UV + vec2(shift + intensity * 0.01, 0.0);
	vec2 uv_g = UV + vec2(shift, 0.0);
	vec2 uv_b = UV + vec2(shift - intensity * 0.01, 0.0);

	float r = texture(TEXTURE, uv_r).r;
	float g = texture(TEXTURE, uv_g).g;
	float b = texture(TEXTURE, uv_b).b;
	float a = texture(TEXTURE, uv_g).a;

	COLOR = vec4(r, g, b, a);
}
