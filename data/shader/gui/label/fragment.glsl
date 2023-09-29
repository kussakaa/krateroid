#version 330  core
uniform sampler2D u_texture0;
uniform vec4 color;
in vec2 v_tex;
out vec4 f_color;
void main()
{
    f_color = color*texture(u_texture0, v_tex);
};