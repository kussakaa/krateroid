#version 330 core
uniform mat4 model;
layout (location = 0) in vec2 a_pos;

void main()
{
    gl_Position = model*vec4(a_pos, 0.0, 1.0);
}
