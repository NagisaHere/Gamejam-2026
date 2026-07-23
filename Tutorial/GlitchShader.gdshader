shader_type canvas_item;

// Captures the screen texture underneath this node
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Shader Controls
uniform float glitch_density : hint_range(0.01, 0.5) = 0.08;   // Percentage of glitched blocks
uniform float block_size : hint_range(5.0, 120.0) = 45.0;      // Grid resolution (larger = smaller blocks)
uniform float flicker_speed : hint_range(1.0, 60.0) = 24.0;    // How fast glitch blocks jump per second
uniform bool enable_scanlines = true;
uniform float scanline_count : hint_range(100.0, 1080.0) = 300.0;
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.12;

// Pseudo-random hash generator
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // Sample the clear screen texture without UV distortion
    vec4 base_color = texture(screen_texture, uv);

    // Quantize time to create a stepped/flickering frame effect
    float time_step = floor(TIME * flicker_speed);

    // Break screen space into blocky grid regions
    vec2 block_grid = floor(uv * block_size) / block_size;

    // Generate random values per block per time step
    float rnd = hash(block_grid + vec2(time_step * 0.17, time_step * 0.43));
    float color_pick = hash(block_grid * 2.5 + vec2(time_step * 0.31, time_step * 0.89));

    // Glitch artifact color palette (Magenta, Neon Green, Cyan, White/Blue)
    vec3 artifact_color = vec3(0.0);
    if (color_pick < 0.25) {
        artifact_color = vec3(1.0, 0.0, 0.55); // Neon Magenta
    } else if (color_pick < 0.50) {
        artifact_color = vec3(0.0, 1.0, 0.25); // Bright Green
    } else if (color_pick < 0.75) {
        artifact_color = vec3(0.0, 0.85, 1.0); // Cyber Cyan
    } else {
        artifact_color = vec3(0.9, 0.95, 1.0); // Blinding White/Blue
    }

    // Apply corrupted pixel block if random value passes the density threshold
    if (rnd < glitch_density) {
        float alpha_mix = hash(block_grid + time_step) * 0.75 + 0.25;
        base_color.rgb = mix(base_color.rgb, artifact_color, alpha_mix);
    }

    // Optional CRT scanlines overlay
    if (enable_scanlines) {
        float scanline = sin(uv.y * scanline_count * 3.14159) * 0.5 + 0.5;
        base_color.rgb *= mix(1.0, scanline, scanline_opacity);
    }

    COLOR = base_color;
}