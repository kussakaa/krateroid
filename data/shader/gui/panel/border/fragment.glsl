#version 330 core
uniform vec4 color;
uniform ivec4 rect;
uniform int width;
out vec4 FragColor;
void main()
{
    if(gl_FragCoord.x > rect.x+width &&
       gl_FragCoord.x < rect.z-width &&
       gl_FragCoord.y > rect.y+width &&
       gl_FragCoord.y < rect.w-width)
    {
        discard;
    } else {
        FragColor = color;
    }
};