shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 0.5, 1.0);
uniform float glow_width : hint_range(0.0, 10.0) = 3.0;
uniform bool glow_enabled = false;

void fragment() {
    vec4 current = texture(TEXTURE, UV);
    vec2 size = TEXTURE_PIXEL_SIZE * glow_width;
    
    float alpha = current.a;
    alpha = max(alpha, texture(TEXTURE, UV + vec2(size.x, 0.0)).a);
    alpha = max(alpha, texture(TEXTURE, UV - vec2(size.x, 0.0)).a);
    alpha = max(alpha, texture(TEXTURE, UV + vec2(0.0, size.y)).a);
    alpha = max(alpha, texture(TEXTURE, UV - vec2(0.0, size.y)).a);
    alpha = max(alpha, texture(TEXTURE, UV + size).a);
    alpha = max(alpha, texture(TEXTURE, UV - size).a);

    vec4 glow = glow_color * vec4(1.0, 1.0, 1.0, alpha - current.a);
    COLOR = mix(current, current + glow, float(glow_enabled));
}