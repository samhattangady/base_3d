#version 330 core
layout (location = 0) in vec3 position;
layout (location = 1) in vec3 normal;
layout (location = 2) in vec4 in_color;
// layout (location = 3) in vec2 in_texCoord;

out vec4 vert_color;
out float vert_shadow;
out vec2 vert_texCoord;
out vec4 shadow_pos;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform mat4 light_view;
uniform mat4 light_proj;

void main()
{
    vec4 out_pos =  model * vec4(position, 1.0);
    gl_Position = projection * view * out_pos;
    shadow_pos = light_proj * light_view * out_pos;
    vec3 light = normalize(vec3(4.2, -1.7, -2.3));
    float l = (dot(light, normal) * 0.5) + 0.5;
    vert_shadow = 1.0 - l;
    vert_color = in_color;
    vert_texCoord = vec2(0.0);
}
