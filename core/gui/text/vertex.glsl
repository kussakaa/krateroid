#version 330 core
layout (location = 0) in vec2 a_pos;
layout (location = 1) in float a_tex;

uniform ivec2 vpsize;
uniform int   scale;
uniform ivec2 pos;

out vec2 v_tex;

void main()
{
    v_tex = vec2(a_tex, a_pos.y);

    mat4 m = mat4(1);
    m[0][0] = 2.0 / float(vpsize.x) * float(scale);
    m[1][1] = 2.0 / float(vpsize.y) * float(scale) * -1.0;
    m[3][0] = float(pos.x) / float(vpsize.x) * 2.0 - 1.0;
    m[3][1] = float(pos.y) / float(vpsize.y) * -2.0 + 1.0;

    gl_Position = m*vec4(a_pos, 0.0, 1.0);
}
