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
    vert_color = vec4(1.0);
    vert_texCoord = vec2(0.0);
}
