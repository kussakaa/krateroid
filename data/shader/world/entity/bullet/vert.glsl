#version 460 core
uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

layout (location = 0) in vec4 a_vertex;

void main()
{
    gl_Position = proj*view*model*a_vertex;
}
