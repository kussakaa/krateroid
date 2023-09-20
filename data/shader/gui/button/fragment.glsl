#version 330 core

uniform ivec4 rect;
uniform ivec2 texsize;

uniform sampler2D button;

in vec2 v_pos;

out vec4 fragcolor;
void main()
{
    vec2 texcoord = vec2(0.5,0.5);
    vec2 fragcoord = gl_FragCoord.xy;

    if (fragcoord.x > rect.x && fragcoord.x < rect.x + texsize.x/2) texcoord.x = float(fragcoord.x - rect.x) / float(texsize.x);
    if (fragcoord.x < rect.z && fragcoord.x > rect.z - texsize.x/2) texcoord.x = float(rect.z - fragcoord.x) / float(texsize.x);

    if (fragcoord.y > rect.y && fragcoord.y < rect.y + texsize.y/2) texcoord.y = float(fragcoord.y - rect.y) / float(texsize.y);
    if (fragcoord.y < rect.w && fragcoord.y > rect.w - texsize.y/2) texcoord.y = float(rect.w - fragcoord.y) / float(texsize.y);

    fragcolor = texture(button, texcoord);
};