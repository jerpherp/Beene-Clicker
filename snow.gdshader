shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 3.0) = 1.0;

void fragment() {
    vec4 color = vec4(0.0);
    vec2 size = TEXTURE_PIXEL_SIZE * blur_amount;
    
    color += texture(TEXTURE, UV + vec2(-size.x, -size.y)) * 0.1;
    color += texture(TEXTURE, UV + vec2(0.0, -size.y)) * 0.15;
    color += texture(TEXTURE, UV + vec2(size.x, -size.y)) * 0.1;
    color += texture(TEXTURE, UV + vec2(-size.x, 0.0)) * 0.15;
    color += texture(TEXTURE, UV) * 0.2;
    color += texture(TEXTURE, UV + vec2(size.x, 0.0)) * 0.15;
    color += texture(TEXTURE, UV + vec2(-size.x, size.y)) * 0.1;
    color += texture(TEXTURE, UV + vec2(0.0, size.y)) * 0.15;
    color += texture(TEXTURE, UV + vec2(size.x, size.y)) * 0.1;
    
    COLOR = color;
}