// --------------------------------------------
// Glowy Shader
// --------------------------------------------
// Fake SSS, duh!
// 

uniform float AmbientIntensity;
uniform float DiffuseIntensity;
uniform float SpecularIntensity;
uniform float Exposure;
uniform vec3 BgColor;
uniform vec2 Resolution;
uniform float Fresnel;
uniform float Waxiness;

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

const float Sharpness = 0.5;

vec3 TRANS_COLOR = BgColor;
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

float beckmannDistribution(float x, float roughness) {
  float NdotH = max(x, 0.0001);
  float cos2Alpha = NdotH * NdotH;
  float tan2Alpha = (cos2Alpha - 1.0) / cos2Alpha;
  float roughness2 = roughness * roughness;
  float denom = 3.141592653589793 * roughness2 * cos2Alpha * cos2Alpha;
  return exp(tan2Alpha / roughness2) / denom;
}

float beckmannSpecular(
  vec3 lightDirection,
  vec3 viewDirection,
  vec3 surfaceNormal,
  float roughness) {
  return beckmannDistribution(dot(surfaceNormal, normalize(lightDirection + viewDirection)), roughness);
}

float cookTorranceSpecular(
  vec3 lightDirection,
  vec3 viewDirection,
  vec3 surfaceNormal,
  float roughness,
  float fresnel) {

  float VdotN = max(dot(viewDirection, surfaceNormal), 0.0);
  float LdotN = max(dot(lightDirection, surfaceNormal), 0.0);

  // Half angle vector
  vec3 H = normalize(lightDirection + viewDirection);

  // Geometric term
  float NdotH = max(dot(surfaceNormal, H), 0.0);
  float VdotH = max(dot(viewDirection, H), 0.000001);
  float LdotH = max(dot(lightDirection, H), 0.000001);
  float G1 = (2.0 * NdotH * VdotN) / VdotH;
  float G2 = (2.0 * NdotH * LdotN) / LdotH;
  float G = min(1.0, min(G1, G2));
  
  // Distribution term
  float D = beckmannDistribution(NdotH, roughness);

  // Fresnel term
  float F = pow(1.0 - VdotN, fresnel);

  // Multiply terms and done
  return  G * F * D / max(3.14159265 * VdotN, 0.000001);
}


void main()
{ 
  vec3 l = normalize(L);
  vec3 n = normalize(N);
  vec3 v = normalize(V);
  // vec3 h = normalize(l+v);

  vec3 ambient = AmbientColour * falloff * TRANS_COLOR * AmbientIntensity;

  vec3 diffuse = (LIGHT_COLOR * DiffuseColour
                           * spotf * falloff
                           * (Waxiness + (1. - Waxiness)
                           * max(0., dot(n, l))) * DiffuseIntensity);

  vec3 specular = LIGHT_COLOR 
                            * spotf * falloff
                            * SpecularColour
                            * cookTorranceSpecular(l, v, n, Roughness, Fresnel) 
                            * SpecularIntensity;

  // Rim silhouette
  float w = 0.18 * (1.0 - Sharpness);
  float rim = 1. - abs(dot(v, n));

  gl_FragColor = vec4(rim * (ambient + diffuse), 1);
  gl_FragColor.rgb += rim * diffuse;
  gl_FragColor *= vec4(ambient + diffuse + specular, rim);
  gl_FragColor += vec4(diffuse + specular, 1);

  // Tone mapping
  gl_FragColor.rgb = Uncharted2Tonemap(gl_FragColor.rgb * Exposure) / Uncharted2Tonemap(vec3(1));

  // Gamma correction
  gl_FragColor.rgb = pow(gl_FragColor.rgb, vec3(1.0 / 2.2));
}

