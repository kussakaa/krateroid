#version 330 core
uniform ivec4 rect;
uniform ivec2 texsize;
//uniform int   scale;
uniform sampler2D button;

in vec2 v_pos;

out vec4 fragcolor;
void main()
{
    vec2 texcoord = v_pos * vec2(rect.z - rect.x, rect.w - rect.y) / texsize;
    //vec2 fragcoord = gl_FragCoord.xy / scale;

    //if (fragcoord.x > rect.x + texsize.x/2 && fragcoord.x < rect.z - texsize.x/2) texcoord.x = 0.5;
    //if (fragcoord.y > rect.y + texsize.y/2 && fragcoord.y < rect.w - texsize.y/2) texcoord.y = 0.5;

    fragcolor = texture(button, texcoord);
};