pub const rect_vertex =
    \\#version 330 core
    \\uniform ivec4 viewport;
    \\layout (location = 0) in vec2 aPos;
    \\void main()
    \\{
    \\   float width = viewport.z;
    \\   float height = viewport.w;
    \\   float ratio = width/height;
    \\   gl_Position = vec4(aPos.x/ratio, aPos.y, 0.0, 1.0);
    \\};
;

pub const rect_fragment =
    \\#version 330 core
    \\uniform vec4 color;
    \\out vec4 FragColor;
    \\void main()
    \\{
    \\   FragColor = color;
    \\};
;
