#version 460 core
in vec4 v_clr;
layout(location = 0) out vec4 f_clr;
void main()
{
    f_clr = v_clr;
}
