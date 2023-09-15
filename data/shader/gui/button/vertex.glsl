#version 330 core
uniform ivec2 vpsize;
uniform ivec4 rect;
layout (location = 0) in vec2 a_pos;

out vec2 v_pos;

void main()
{
    v_pos = a_pos;
    float vpx = float(vpsize.x);
    float vpy = float(vpsize.y);
    vec2 pos = vec2(-1.0+float(rect.x)/vpx*2.0, -1.0+float(rect.y)/vpy*2.0);
    vec2 ratio = vec2(1.0/vpx*float(rect.z-rect.x)*2.0, 1.0/vpy *float(rect.w-rect.y)*2.0);
    gl_Position = vec4(v_pos.x*ratio.x+pos.x, v_pos.y*ratio.y+pos.y, 0.0, 1.0);
};