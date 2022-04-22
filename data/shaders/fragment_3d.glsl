#version 330 core

layout(location = 0) out vec4 frag_color;

in vec4 vert_color;
in vec2 vert_texCoord;

uniform sampler2D tex;
uniform int debug;

void main()
{
    vec4 col;
    col = texture(tex, vert_texCoord.xy);
    // float bw = (vert_color.r + vert_color.g + vert_color.b) / 3;
    // frag_color = vec4(bw, bw, bw, col.r*vert_color.a);
    // frag_color = vec4(vert_color.rgb, col.r*vert_color.a);
    vec4 col2 = vec4(0.4, 0.3, 0.7, 1.0);
    if (debug == 1) {
        col2 = vec4(1.7, 0.3, 0.4, 1.0);
    }
    frag_color = mix(col2, vert_color, 0.9);
} 
