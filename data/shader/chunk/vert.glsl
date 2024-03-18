#version 460 core
uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

layout (location = 0) in vec3 a_pos;
layout (location = 1) in vec3 a_nrm;

struct LightInfo {
  vec4 color;
  vec4 direction;
  float ambient;
  float diffuse;
  float specular;
};

uniform LightInfo light;

struct ChunkInfo {
  float width;
  vec3 pos;
  vec4 color;
};

uniform ChunkInfo chunk;

out vec3 v_pos;
out vec3 v_nrm;
out vec3 v_light;

void main()
{
  v_pos = a_pos;
  v_nrm = normalize(a_nrm);

  vec3 n = normalize((mat4(transpose(inverse(model))) * vec4(normalize(a_nrm), 1.0)).xyz);
  vec3 l = normalize(light.direction.xyz);
  float a = light.ambient;
  float nds = max(dot(l, n), 0.0);
  float d = light.diffuse*nds;
  float s = 0.0;
  if(nds > 0.0) {
    vec3 v = normalize((inverse(view)*vec4(0.0,0.0,1.0,0.0)).xyz);
    vec3 r = reflect(-l, n);
    s = light.specular*pow(max(dot(v, r), 0.0), 1);
  }
  v_light = light.color.xyz * (a + d + s);
  gl_Position = proj*view*model*vec4(v_pos + chunk.pos * chunk.width, 1.0);
}
