#version 330 core

uniform ivec2 vpsize;
uniform ivec4 rect;
uniform ivec4 texrect;
uniform int   scale;
uniform sampler2D texture0;
layout(location = 0) out vec4 f_color;

void main()
{
    vec2 fragpos = vec2(gl_FragCoord.x, vpsize.y - gl_FragCoord.y);

    vec2 texsize = vec2(textureSize(texture0, 0));
    vec2 texrectsize = vec2(texrect.z - texrect.x, texrect.w - texrect.y);
    vec2 tex = vec2(texrect.x + texrect.z, texrect.y + texrect.w)/2/texsize;

    if (fragpos.x > rect.x && fragpos.x < rect.x + texrectsize.x*scale/2)
        tex.x = float(fragpos.x - rect.x + texrect.x * scale) / float(texsize.x) / scale;
    if (fragpos.x < rect.z && fragpos.x > rect.z - texrectsize.x*scale/2)
        tex.x = float(fragpos.x - rect.z + texrect.z * scale) / float(texsize.x) / scale;
    if (fragpos.y > rect.y && fragpos.y < rect.y + texrectsize.y*scale/2)
        tex.y = float(fragpos.y - rect.y + texrect.y * scale) / float(texsize.y) / scale;
    if (fragpos.y < rect.w && fragpos.y > rect.w - texrectsize.y*scale/2)
        tex.y = float(fragpos.y - rect.w + texrect.w * scale) / float(texsize.y) / scale;

    f_color = texture(texture0, tex);
}
