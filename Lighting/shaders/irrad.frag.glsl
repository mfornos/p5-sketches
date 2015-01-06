// --------------------------------------------
// Irradiance Shader
// --------------------------------------------

uniform float AmbientIntensity;
uniform float DiffuseIntensity;
uniform float SpecularIntensity;
uniform float Exposure;
uniform vec3 BgColor;
uniform vec2 Resolution;
uniform float Fresnel;

const float albedo = 0.15;

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

void main()
{ 

  vec3 l = normalize(L);
  vec3 n = normalize(N);
  vec3 v = normalize(V);
  // vec3 h = normalize(l+v);

  float diffuse = max(.0, dot(l,n));

  // Irradiance
  vec3 irrad = vec3( 
     albedo * irradmat(gracered, n),
     albedo * irradmat(gracegreen, n),
     albedo * irradmat(graceblue, n));

  gl_FragColor = vec4((AmbientColour * falloff * AmbientIntensity + 
                      DiffuseColour * spotf * falloff * diffuse*DiffuseIntensity +
                      SpecularColour * spotf * falloff 
                      * beckmannSpecular(l,v,n,Roughness)*SpecularIntensity) * 0.5 +
                      smoothstep(.0, 1.5, irrad * 50. * diffuse),
                  1);

  // Tone Mapping
  gl_FragColor.rgb = Uncharted2Tonemap(gl_FragColor.rgb * Exposure) 
                     / Uncharted2Tonemap(vec3(1));
  // Gamma correction
  gl_FragColor.rgb = pow(gl_FragColor.rgb, vec3(1.0 / 2.2));
}

