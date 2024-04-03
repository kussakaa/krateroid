#version 460 core
uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

layout (location = 0) in vec4 a_vertex;
layout (location = 1) in vec4 a_color;

out vec4 v_color;

void main()
{
    v_color = a_color;
    gl_Position = proj*view*model*a_vertex;
}
