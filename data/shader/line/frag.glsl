#version 460 core
uniform vec4 color;
layout(location = 0) out vec4 f_color;
void main()
{
    f_color = vec4(color);
}
