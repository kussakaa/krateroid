pub const main_vertex =
    \\#version 330 core
    \\uniform mat4 model;
    \\uniform mat4 view;
    \\uniform mat4 proj;
    \\layout (location = 0) in vec3 aPos;
    \\layout (location = 1) in vec3 aCol;
    \\out vec3 vCol;
    \\void main()
    \\{
    \\   vCol = aCol;
    \\   gl_Position = proj*view*model*vec4(aPos.x, aPos.y, aPos.z, 1.0);
    \\};
;

pub const main_fragment =
    \\#version 330 core
    \\in vec3 vCol;
    \\uniform vec4 color;
    \\out vec4 FragColor;
    \\void main()
    \\{
    \\   FragColor = color;
    \\};
;
