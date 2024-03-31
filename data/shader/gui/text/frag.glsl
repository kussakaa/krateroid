#version 460 core

uniform sampler2D texture0;
uniform ivec2 vpsize;
uniform int   scale;
uniform ivec2 pos;
uniform ivec2 tex;
uniform vec4  color;

layout(location = 0) out vec4 f_color;

void main()
{
    vec2 fragpos = vec2(gl_FragCoord.x, vpsize.y - gl_FragCoord.y);
    vec2 texsize = vec2(textureSize(texture0, 0));
    vec2 texres = vec2(fragpos.x - pos.x + tex.x * scale, fragpos.y - pos.y) / texsize / scale;
    f_color = color*vec4(1.0,1.0,1.0,texture(texture0, texres).r);
}
