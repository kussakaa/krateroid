#version 330 core
uniform vec4 color;
//in vec3 v_light;
layout(location = 0) out vec4 f_color;
void main()
{
    //f_color = vec4(color.xyz*v_light, color.w);
    f_color = vec4(color);
}
