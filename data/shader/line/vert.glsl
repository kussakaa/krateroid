#version 460 core
uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

layout (location = 0) in vec3 a_pos;
layout (location = 1) in vec4 a_clr;

out vec4 v_clr;

void main()
{
    v_clr = a_clr;
    gl_Position = proj*view*model*vec4(a_pos, 1.0);
}
