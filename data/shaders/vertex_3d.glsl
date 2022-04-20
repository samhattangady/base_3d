#version 330 core
layout (location = 0) in vec3 position;
layout (location = 1) in vec3 normal;
// layout (location = 2) in vec4 in_color;
// layout (location = 3) in vec2 in_texCoord;

out vec4 vert_color;
out vec2 vert_texCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    gl_Position = projection * view * model * vec4(position, 1.0);
    vec3 light = normalize(vec3(1.0, -16.0, 1.0));
    float l = (dot(light, normal) * 0.5) + 0.5;
    vert_color = vec4(vec3(l), 1.0);
    vert_texCoord = vec2(0.0);
}
