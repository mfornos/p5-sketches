// --------------------------------------------
// Transmission Shader
// --------------------------------------------

#define PI 3.14159265

uniform sampler2D texture;

uniform float aK;
uniform float dK;
uniform float sK;

uniform float Exposure;
uniform float Fresnel;
uniform float TransmitMin;
uniform float TransmitMax;

varying vec3 aC;
varying vec3 dC;
varying vec3 sC;

varying vec3 N;
varying vec3 P;
varying vec3 V;
varying vec3 L;

varying float I;
varying float Roughness;

const float Thinness = 3.;
const vec3 CF = vec3(1.0 / 2.2);


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

float orenNayarDiffuse(
  vec3 lightDirection,
  vec3 viewDirection,
  vec3 surfaceNormal,
  float roughness,
  float albedo) {
  
  float LdotV = dot(lightDirection, viewDirection);
  float NdotL = dot(lightDirection, surfaceNormal);
  float NdotV = dot(surfaceNormal, viewDirection);

  float s = LdotV - NdotL * NdotV;
  float t = mix(1.0, max(NdotL, NdotV), step(0.0, s));

  float sigma2 = roughness * roughness;
  float A = 1.0 + sigma2 * (albedo / (sigma2 + 0.13) + 0.5 / (sigma2 + 0.33));
  float B = 0.45 * sigma2 / (sigma2 + 0.09);

  return albedo * max(0.0, NdotL) * (A + B * s / t) / PI;
}


void main()
{ 
  vec3 l = normalize(L);
  vec3 n = normalize(N);
  vec3 v = normalize(V);
  vec3 p = normalize(P);

  float diffuse = orenNayarDiffuse(l, v, n, Roughness, 0.35);
  float specular = ggxSpecular(l, v, n, Roughness, Fresnel);
   
  gl_FragColor = vec4(aC * aK +
                      I * (dC * diffuse * dK +
                      sC * specular * sK), 1);

  float t1 = TransmitMax * (1. - pow(1. - n.z, Thinness));
  vec3 r = reflect(v, n);
  float m = 2.0 * sqrt( r.x*r.x + r.y*r.y + (r.z+1.0)*(r.z+1.0) );
  vec4 env = texture2D(texture, vec2(r.x/m + 0.5, r.y/m + 0.5));
  float extinction = 5.;
  gl_FragColor.rgb += I * exp(-extinction * (1.-TransmitMin - ((1. - t1) * gl_FragColor.rgb + t1 * env.rgb)))
                      * diffuse;

  // Tone mapping
  gl_FragColor.rgb = Uncharted2Tonemap(gl_FragColor.rgb * Exposure) / Uncharted2Tonemap(vec3(1));

  // Gamma correction
  gl_FragColor.rgb = pow(gl_FragColor.rgb, CF);

}
