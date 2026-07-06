
shader_type canvas_item;

uniform float inner_radius = 0.3;
uniform float outer_radius = 0.5;

void fragment() {
    float dist = distance(UV, vec2(0.5));

    float alpha = 1.0 - smoothstep(inner_radius, outer_radius, dist);

    COLOR = vec4(1.0, 1.0, 1.0, alpha);
}
