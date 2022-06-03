#version 330 core

layout(location = 0) out vec4 frag_color;

in vec4 vert_color;
in vec4 vert_shadow;
in vec2 vert_texCoord;
in vec4 shadow_pos;

uniform sampler2D shadow_map;
uniform int debug;
uniform vec4 color;

float shadow_calculation(vec4 pos) {
    vec2 tex_coord = pos.xy / pos.w;
    tex_coord = (tex_coord * 0.5) + vec2(0.5);
    if (tex_coord.x < 0.0 || tex_coord.x > 1.0 || tex_coord.y < 0.0 || tex_coord.y > 1.0) {
        return 0.0;
    }
    float shadow_depth = texture(shadow_map, tex_coord).r;
    float depth = pos.z / pos.w;
    depth = 0.5 + (depth * 0.5);
    float bias = 0.00005;
    float shadow = depth - bias > shadow_depth ? 1.0 : 0.0;
    return shadow;
}

void main() {
    vec4 col = vert_color;
    // TODO (16 May 2022 sam): Should this be passed as uniform?
    float texel_size = 1.0 / 2096.0;
    float shadow = 0.0;
    for(int x = -3; x <= 3; ++x)
    {
        for(int y = -3; y <= 3; ++y)
        {
            vec4 new_pos = vec4(shadow_pos.xy + (vec2(x,y) * texel_size), shadow_pos.zw);
            shadow += shadow_calculation(new_pos);        
        }    
    }
    shadow /= 49.0;
    frag_color = mix(col, vec4(0.0, 0.0, 0.0, 1.0), vert_shadow * 0.1);
    frag_color = mix(frag_color, vec4(0.0, 0.0, 0.0, 1.0), shadow * 0.2);
    frag_color.w = vert_color.w;
} 

