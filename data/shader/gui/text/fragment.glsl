#version 330  core
uniform sampler2D u_texture0;
uniform vec4 color;
out vec4 FragColor;
void main()
{
    FragColor = vec4(color.x, color.y, color.z, color.w*texture(u_texture0, v_tex).r);
};