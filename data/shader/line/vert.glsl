#version 330 core
uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

layout (location = 0) in vec3 a_pos;

void main()
{
    gl_Position = proj*view*model*vec4(a_pos, 1.0);
}
