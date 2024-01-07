#version 330 core

uniform vec4 color;
uniform sampler2D u_texture0;

in vec2 v_tex;
layout(location = 0) out vec4 f_color;

void main()
{
    vec2 tex_size = vec2(textureSize(u_texture0, 0));
    vec2 tex = vec2(v_tex.x/tex_size.x, v_tex.y/tex_size.y);
    f_color = color*vec4(1.0,1.0,1.0,texture(u_texture0, tex).r);
}
