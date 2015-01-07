// --------------------------------------------
// Irradiance Shader
// --------------------------------------------

#define PI 3.14159265

uniform float AmbientIntensity;
uniform float DiffuseIntensity;
uniform float SpecularIntensity;
uniform float Exposure;
uniform vec3 BgColor;
uniform vec2 Resolution;
uniform float Fresnel;

const float albedo = 0.65;

varying vec3 AmbientColour;
varying vec3 DiffuseColour;
varying vec3 SpecularColour;
varying float Roughness;

varying vec3 N;
varying vec3 P;
varying vec3 V;
varying vec3 L;
varying float spotf;
varying float falloff;

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

mat4 gracered = mat4(
  0.009098, -0.004780,  0.024033, -0.014947,
 -0.004780, -0.009098, -0.011258,  0.020210,
  0.024033, -0.011258, -0.011570, -0.017383, 
 -0.014947,  0.020210, -0.017383,  0.073787 );

mat4 gracegreen = mat4(
  -0.002331, -0.002184,  0.009201, -0.002846,
  -0.002184,  0.002331, -0.009611,  0.017903,
   0.009201, -0.009611, -0.007038, -0.009331,
  -0.002846,  0.017903, -0.009331,  0.041083 );

mat4 graceblue = mat4(
  -0.013032, -0.005248,  0.005970,  0.000483,
  -0.005248,  0.013032, -0.020370,  0.030949,
   0.005970, -0.020370, -0.010948, -0.013784,
   0.000483,  0.030949, -0.013784,  0.051648 );

float irradmat(mat4 M, vec3 v)
{
    vec4 n = vec4(v, 1);
    return dot(n, M * n);
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
  // vec3 h = normalize(l+v);

  float diffuse = orenNayarDiffuse(l,v,n,Roughness,albedo);

  // Irradiance
  vec3 irrad = vec3( 
     albedo * irradmat(gracered, n),
     albedo * irradmat(gracegreen, n),
     albedo * irradmat(graceblue, n));

  gl_FragColor = vec4(AmbientColour * falloff * AmbientIntensity
                      + DiffuseColour * spotf * falloff * diffuse * DiffuseIntensity 
                      + SpecularColour * spotf * falloff 
                      * ggxSpecular(l,v,n,Roughness,Fresnel) * SpecularIntensity,
                  1);
  float extinction = 15.;
  gl_FragColor.rgb += exp(-extinction * (irrad * 10.)) * diffuse;

  // Tone Mapping
  gl_FragColor.rgb = Uncharted2Tonemap(gl_FragColor.rgb * Exposure) 
                     / Uncharted2Tonemap(vec3(1));
  // Gamma correction
  gl_FragColor.rgb = pow(gl_FragColor.rgb, vec3(1.0 / 2.2));
}

