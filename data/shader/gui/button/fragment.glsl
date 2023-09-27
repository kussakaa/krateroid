#version 330 core

uniform ivec2 vpsize;
uniform int   scale;
uniform ivec4 rect;
uniform ivec2 texsize;

uniform sampler2D button;
in vec2 v_pos;
out vec4 f_color;

void main()
{
    vec2 f_coord = gl_FragCoord.xy;

    vec2 tex_coord = vec2(0.5,0.5);
    vec2 tex_size = vec2(texsize) * vec2(scale);

    if (f_coord.x > rect.x && f_coord.x < rect.x + tex_size.x/2) tex_coord.x = float(f_coord.x - rect.x) / float(tex_size.x);
    if (f_coord.x < rect.z && f_coord.x > rect.z - tex_size.x/2) tex_coord.x = float(f_coord.x - rect.x) / float(tex_size.x);

    if (f_coord.y > rect.y && f_coord.y < rect.y + tex_size.y/2) tex_coord.y = 1.0 - float(f_coord.y - rect.y) / float(tex_size.y);
    if (f_coord.y < rect.w && f_coord.y > rect.w - tex_size.y/2) tex_coord.y = 1.0 - float(f_coord.y - rect.y) / float(tex_size.y);

    f_color = texture(button, tex_coord);
};