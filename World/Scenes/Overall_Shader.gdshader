shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float vignette_intensity : hint_range(0.0, 3.0) = 0.8;
uniform float grain_amount : hint_range(0.0, 0.2) = 0.04;

// Simple random generator for grain
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 color = texture(screen_texture, uv);
    
    // Calculate Vignette (distance from center)
    float dist = distance(uv, vec2(0.5));
    float vignette = smoothstep(0.8, 0.2, dist * vignette_intensity);
    
    // Calculate Grain
    float grain = (random(uv + vec2(TIME)) - 0.5) * grain_amount;
    
    // Combine
    vec3 final_rgb = (color.rgb + grain) * vignette;
    COLOR = vec4(final_rgb, color.a);
}