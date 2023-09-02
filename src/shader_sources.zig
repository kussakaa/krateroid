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
    \\
    \\layout (location = 0) in vec3 a_pos;
    \\layout (location = 1) in vec3 a_nrm;
    \\
    \\struct CameraInfo {
    \\    vec3 direction;
    \\};
    \\
    \\uniform CameraInfo camera;
    \\
    \\struct LightInfo {
    \\    vec3 color;
    \\    vec3 direction;
    \\    float ambient;
    \\    float diffuse;
    \\    float specular;
    \\};
    \\
    \\uniform LightInfo light;
    \\
    \\out vec3 v_light;
    \\
    \\void main()
    \\{
    \\    vec3 n = normalize((mat4(transpose(inverse(model))) * vec4(normalize(a_nrm), 1.0)).xyz);
    \\    vec3 l = normalize(light.direction);
    \\    float a = light.ambient;
    \\    float nds = max(dot(l, n), 0.0);
    \\    float d = light.diffuse*nds;
    \\    float s = 0.0;
    \\    if(nds > 0.0) {
    \\        vec3 v = normalize((inverse(view)*vec4(0.0,0.0,1.0,1.0)).xyz);
    \\        vec3 r = reflect(-l, n);
    \\        s = light.specular*pow(max(dot(r, v), 0.0), 3);
    \\    }
    \\    v_light = light.color * (a + d + s);
    \\    gl_Position = proj*view*model*vec4(a_pos, 1.0);
    \\}
;

pub const shape_fragment =
    \\#version 330 core
    \\uniform vec4 color;
    \\in vec3 v_light;
    \\layout(location = 0) out vec4 FragColor;
    \\void main()
    \\{
    \\    FragColor = vec4(color.xyz*v_light, color.w);
    \\}
;
