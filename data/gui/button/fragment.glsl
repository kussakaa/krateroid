#version 330 core

uniform ivec2 vpsize;
uniform ivec4 rect;
uniform int   scale;
uniform sampler2D u_texture0;
layout(location = 0) out vec4 f_color;

void main()
{
    vec2 f_coord = vec2(gl_FragCoord.x, vpsize.y - gl_FragCoord.y);

    vec2 tex = vec2(0.5,0.5);
    vec2 tex_size = vec2(textureSize(u_texture0, 0)) * vec2(scale);

    if (f_coord.x > rect.x && f_coord.x < rect.x + tex_size.x/2) tex.x = float(f_coord.x - rect.x) / float(tex_size.x);
    if (f_coord.x < rect.z && f_coord.x > rect.z - tex_size.x/2) tex.x = float(f_coord.x - rect.x) / float(tex_size.x);
    if (f_coord.y > rect.y && f_coord.y < rect.y + tex_size.y/2) tex.y = float(f_coord.y - rect.y) / float(tex_size.y);
    if (f_coord.y < rect.w && f_coord.y > rect.w - tex_size.y/2) tex.y = float(f_coord.y - rect.y) / float(tex_size.y);

    f_color = texture(u_texture0, tex);
}
