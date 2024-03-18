#version 460 core
layout (location = 0) in vec2 a_pos;

uniform ivec2 vpsize;
uniform int   scale;
uniform ivec2 pos;
uniform ivec2 tex;

void main()
{
    mat4 m = mat4(1);
    m[0][0] = float(tex.y * scale) / float(vpsize.x) * 2.0;
    m[1][1] = float(8 * scale) / float(vpsize.y) * 2.0 * -1.0;
    m[3][0] = float(pos.x) / float(vpsize.x) * 2.0 - 1.0;
    m[3][1] = float(pos.y) / float(vpsize.y) * -2.0 + 1.0;

    gl_Position = m*vec4(a_pos, 0.0, 1.0);
}
