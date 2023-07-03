// исходные кода шейдеров

pub const rect_vertex =
    \\#version 330 core
    \\uniform ivec4 rect;
    \\uniform ivec2 vpsize;
    \\layout (location = 0) in vec2 a_pos;
    \\void main()
    \\{
    \\    float vpwidth = float(vpsize.x);
    \\    float vpheight = float(vpsize.y);
    \\    vec2 pos = vec2(-1.0+float(rect.x)/vpwidth*2.0, -1.0+float(rect.y)/vpheight*2.0);
    \\    vec2 ratio = vec2(1.0/vpwidth*float(rect.z-rect.x)*2.0, 1.0/vpheight*float(rect.w-rect.y)*2.0);
    \\    gl_Position = vec4(a_pos.x*ratio.x+pos.x, a_pos.y*ratio.y+pos.y, 0.0, 1.0);
    \\};
;

pub const rect_fragment =
    \\#version 330  core
    \\uniform vec4  color;
    \\uniform ivec4 rect;
    \\uniform int   borders_width;
    \\uniform vec4  borders_color;
    \\out vec4 FragColor;
    \\void main()
    \\{
    \\    if(gl_FragCoord.x > rect.x+borders_width &&
    \\       gl_FragCoord.x < rect.z-borders_width &&
    \\       gl_FragCoord.y > rect.y+borders_width &&
    \\       gl_FragCoord.y < rect.w-borders_width) {
    \\        FragColor = color;
    \\    } else {
    \\        FragColor = borders_color;
    \\    }
    \\};
;

pub const text_vertex =
    \\#version 330 core
    \\uniform ivec4 rect;
    \\uniform ivec2 vpsize;
    \\layout (location = 0) in vec2 a_pos;
    \\layout (location = 1) in vec2 a_tex;
    \\out vec2 v_tex;
    \\void main()
    \\{
    \\    v_tex = a_tex;
    \\    float vpwidth = float(vpsize.x);
    \\    float vpheight = float(vpsize.y);
    \\    vec2 pos = vec2(-1.0+float(rect.x)/vpwidth*2.0, -1.0+float(rect.y)/vpheight*2.0);
    \\    vec2 ratio = vec2(1.0/vpwidth*float(rect.z-rect.x)*2.0, 1.0/vpheight*float(rect.w-rect.y)*2.0);
    \\    gl_Position = vec4(a_pos.x*ratio.x+pos.x, a_pos.y*ratio.y+pos.y, 0.0, 1.0);
    \\};
;

pub const text_fragment =
    \\#version 330  core
    \\uniform sampler2D u_texture0;
    \\uniform vec4 color;
    \\in vec2 v_tex;
    \\out vec4 FragColor;
    \\void main()
    \\{
    \\    FragColor = vec4(color.x, color.y, color.z, color.w*texture(u_texture0, v_tex).r);
    \\};
;

pub const shape_vertex =
    \\#version 330 core
    \\uniform mat4 model;
    \\uniform mat4 view;
    \\uniform mat4 proj;
    \\layout (location = 0) in vec3 a_pos;
    \\layout (location = 1) in vec3 a_nrm;
    \\out vec3 normal;
    \\void main()
    \\{
    \\    normal = normalize(a_nrm);
    \\    gl_Position = proj*view*model*vec4(a_pos, 1.0);
    \\}
;

pub const shape_fragment =
    \\#version 330 core
    \\uniform vec3 light_direction;
    \\uniform float light_intensity;
    \\uniform float light_ambient;
    \\in vec3 normal;
    \\out vec4 FragColor;
    \\void main()
    \\{
    \\    vec3 color = vec3(1.0, 1.0, 1.0);
    \\    vec3 lightdir = normalize(light_direction);;
    \\    float li = light_intensity;
    \\    float la = 0.3;
    \\    FragColor = vec4(color*(la+li*max(0.0, dot(normal, lightdir))), 1.0);
    \\}
;
