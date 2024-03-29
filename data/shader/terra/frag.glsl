#version 460 core

in vec3 v_vertex;
in vec3 v_normal;
in vec3 v_light;

layout(location = 0) out vec4 f_color;

float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

uniform sampler2D texture0;

float noise(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

void main()
{
    float noise = clamp(noise(v_vertex) + 0.5, 0.9, 1.0);
    vec3 v = v_vertex;
    vec3 n = normalize(max(abs(v_normal), 0.00001));
    n /= vec3(n.x + n.y + n.z);
    vec3 t = vec3(texture(texture0, v.xy * (1.0 / 8.0)) * n.z +
		  texture(texture0, v.xz * (1.0 / 8.0)) * n.y +
		  texture(texture0, v.yz * (1.0 / 8.0)) * n.x);
    f_color = vec4(v_light * t, 1.0);
}
