#version 330 core
uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

layout (location = 0) in vec3 a_pos;
layout (location = 1) in vec3 a_nrm;
//
//struct CameraInfo {
//    vec3 direction;
//};
//
//uniform CameraInfo camera;
//
//struct LightInfo {
//    vec3 color;
//    vec3 direction;
//    float ambient;
//    float diffuse;
//    float specular;
//};
//
//uniform LightInfo light;
//
out vec3 v_light;


void main()
{
    vec3 n = normalize((mat4(transpose(inverse(model))) * vec4(normalize(a_nrm), 1.0)).xyz);
    //vec3 l = normalize(light.direction);
    //float a = light.ambient;
    //float nds = max(dot(l, n), 0.0);
    //float d = light.diffuse*nds;
    //float s = 0.0;
    //if(nds > 0.0) {
    //    vec3 v = normalize((inverse(view)*vec4(0.0,0.0,1.0,1.0)).xyz);
    //    vec3 r = reflect(-l, n);
    //    s = light.specular*pow(max(dot(r, v), 0.0), 3);
    //}
    v_light = n;//light.color * (a + d + s);
    gl_Position = proj*view*model*vec4(a_pos, 1.0);
}
