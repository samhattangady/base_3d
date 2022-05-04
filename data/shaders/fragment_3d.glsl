#version 330 core

layout(location = 0) out vec4 frag_color;

in vec4 vert_color;
in vec2 vert_texCoord;
in vec4 shadow_pos;

uniform sampler2D tex;
uniform sampler2D shadow_map;
uniform int debug;

float shadow_calculation(vec4 pos) {
    vec2 tex_coord = pos.xy / pos.w;
    tex_coord = (tex_coord * 0.5) + vec2(0.5);
    if (tex_coord.x < 0.0 || tex_coord.x > 1.0 || tex_coord.y < 0.0 || tex_coord.y > 1.0) {
        return 0.0;
    }
    float shadow_depth = texture(shadow_map, tex_coord).r;
    float depth = pos.z / pos.w;
    depth = 0.5 + (depth * 0.5);
    float shadow = depth > shadow_depth ? 1.0 : 0.0;
    return shadow;
}

void main() {
    vec4 col = vec4(0.65, 0.5, 0.7, 1.0);
    float in_shade = shadow_calculation(shadow_pos);
    frag_color = mix(col, vert_color, 0.1);
    frag_color = mix(frag_color, vec4(0.0, 0.0, 0.0, 1.0), in_shade * 0.4);
} 
