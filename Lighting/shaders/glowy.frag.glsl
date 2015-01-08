// --------------------------------------------
// Glowy Shader
// --------------------------------------------
// Fake SSS, duh!
// 

#define PI 3.14159265

uniform float aK;
uniform float dK;
uniform float sK;

uniform float Waxiness;
uniform float Exposure;
uniform float Fresnel;

varying vec3 aC;
varying vec3 dC;
varying vec3 sC;

varying vec3 N;
varying vec3 P;
varying vec3 V;
varying vec3 L;

varying float I;
varying float Roughness;

const float Sharpness = 0.5;
const vec3 LIGHT_COLOR = vec3(.9, .9, 1);

vec3 Uncharted2Tonemap(vec3 x)
{
  float A = 0.15;
  float B = 0.50;
  float C = 0.10;
  float D = 0.20;
  float E = 0.02;
  float F = 0.30;

  return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

float G1V(float dotNV, float k)
{
  return 1.0/(dotNV*(1.0-k)+k);
}

float ggxSpecular(vec3 L, vec3 V, vec3 N, float roughness, float F0)
{
  float alpha = roughness*roughness;

  vec3 H = normalize(V+L);

  float dotNL = clamp(dot(N,L), 0., 1.);
  float dotNH = clamp(dot(N,H), 0., 1.);
  float dotLH = clamp(dot(L,H), 0., 1.);

  float F, D, vis;

  // D
  float alphaSqr = alpha*alpha;
  float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0;
  D = alphaSqr/(PI * denom * denom);

  // F
  float dotLH5 = pow(1.0-dotLH,5.);
  F = F0 + (1.0-F0)*(dotLH5);

  // V
  float k = alpha/2.0;
  vis = G1V(dotLH,k)*G1V(dotLH,k);

  float specular = dotNL * D * F * vis;
  return specular;
}

void main()
{ 
  vec3 l = normalize(L);
  vec3 n = normalize(N);
  vec3 v = normalize(V);

  vec3 ambient = aC * aK;
  vec3 diffuse = I * LIGHT_COLOR * dC * dK
                           * (Waxiness + (1. - Waxiness)
                           * max(0., dot(n, l)));
  vec3 specular = I * LIGHT_COLOR 
                            * sC * sK
                            * ggxSpecular(l, v, n, Roughness, Fresnel);

  // Rim silhouette
  float w = 0.18 * (1.0 - Sharpness);
  float rim = 1. - abs(dot(v, n)); // abs illuminate 2 sides

  gl_FragColor = vec4(rim * (ambient + diffuse), 1);
  gl_FragColor.rgb += rim * diffuse;
  gl_FragColor *= vec4(ambient + diffuse + specular, rim);
  gl_FragColor += vec4(diffuse + specular, 1);

  // Tone mapping
  gl_FragColor.rgb = Uncharted2Tonemap(gl_FragColor.rgb * Exposure) / Uncharted2Tonemap(vec3(1));

  // Gamma correction
  gl_FragColor.rgb = pow(gl_FragColor.rgb, vec3(1.0 / 2.2));
}

