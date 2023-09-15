#version 330 core
uniform ivec4 rect;
uniform ivec2 vpsize;
layout (location = 0) in vec2 a_pos;
layout (location = 1) in vec2 a_tex;
out vec2 v_tex;
void main()
{
    v_tex = a_tex;
    float vpwidth = float(vpsize.x);
    float vpheight = float(vpsize.y);
    vec2 pos = vec2(-1.0+float(rect.x)/vpwidth*2.0, -1.0+float(rect.y)/vpheight*2.0);
    vec2 ratio = vec2(1.0/vpwidth*float(rect.z-rect.x)*2.0, 1.0/vpheight*float(rect.w-rect.y)*2.0);
    gl_Position = vec4(a_pos.x*ratio.x+pos.x, a_pos.y*ratio.y+pos.y, 0.0, 1.0);
};