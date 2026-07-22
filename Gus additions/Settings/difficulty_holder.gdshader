shader_type canvas_item;

uniform vec4 stripe_color_1 : source_color = vec4(1.0, 0.8, 0.0, 1.0); // Yellow
uniform vec4 stripe_color_2 : source_color = vec4(0.1, 0.1, 0.1, 1.0); // Dark gray
uniform float frequency : hint_range(1.0, 50.0) = 15.0;
uniform float scroll_speed : hint_range(-5.0, 5.0) = 0.5;

void fragment() {
    // Offset UVs diagonally and add TIME for animation
    float pos = (UV.x + UV.y) * frequency + (TIME * scroll_speed);
    
    // Split into repeating bands
    float pattern = step(0.5, fract(pos));
    
    COLOR = mix(stripe_color_1, stripe_color_2, pattern);
}