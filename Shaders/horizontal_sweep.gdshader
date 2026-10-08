shader_type canvas_item;

uniform float progress: hint_range(0.0, 1.0);
uniform bool reverse = true;

void fragment() {
	if(UV.x > progress){
		discard;
	}
}
