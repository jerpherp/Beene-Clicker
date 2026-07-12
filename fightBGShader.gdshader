shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 10.0) = 2.0;

void fragment() {
    vec4 color = vec4(0.0);
    vec2 size = TEXTURE_PIXEL_SIZE * blur_amount;
    
    color += texture(TEXTURE, UV + vec2(-size.x, -size.y)) * 0.077;
    color += texture(TEXTURE, UV + vec2(0.0, -size.y)) * 0.123;
    color += texture(TEXTURE, UV + vec2(size.x, -size.y)) * 0.077;
    color += texture(TEXTURE, UV + vec2(-size.x, 0.0)) * 0.123;
    color += texture(TEXTURE, UV) * 0.2;
    color += texture(TEXTURE, UV + vec2(size.x, 0.0)) * 0.123;
    color += texture(TEXTURE, UV + vec2(-size.x, size.y)) * 0.077;
    color += texture(TEXTURE, UV + vec2(0.0, size.y)) * 0.123;
    color += texture(TEXTURE, UV + vec2(size.x, size.y)) * 0.077;
    
    COLOR = color;
}