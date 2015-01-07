// --------------------------------------------
// Transmission Shader
// --------------------------------------------

#define PI 3.14159265

uniform sampler2D texture;

uniform float AmbientIntensity;
uniform float DiffuseIntensity;
uniform float SpecularIntensity;
uniform float Exposure;
uniform vec3 BgColor;
uniform vec2 Resolution;
uniform float Fresnel;
uniform float TransmitMin;
uniform float TransmitMax;

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

const float Thinness = 3.;


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
  // vec3 h = normalize(l+v);
  vec3 p = normalize(P);

  float diffuse = max(0., dot(l,n));

  float specular = ggxSpecular(l, v, n, Roughness, Fresnel);
   
  gl_FragColor = vec4(AmbientColour * falloff * AmbientIntensity +
                      DiffuseColour * spotf * falloff * diffuse * DiffuseIntensity +
                      SpecularColour * spotf * falloff * specular * SpecularIntensity, 1);

  float t1 = max(TransmitMin + (TransmitMax - TransmitMin) * (1. - pow(1. - n.z, Thinness)), 0.);
  vec3 r = reflect(v, n);
  float m = 2.0 * sqrt( r.x*r.x + r.y*r.y + (r.z+1.0)*(r.z+1.0) );
  vec4 env = texture2D(texture, vec2(r.x/m + 0.5, r.y/m + 0.5));
  gl_FragColor.rgb = 0.75 * diffuse * ((1. - t1) * gl_FragColor.rgb + t1 * env.rgb);

  // Tone mapping
  gl_FragColor.rgb = Uncharted2Tonemap(gl_FragColor.rgb * Exposure) / Uncharted2Tonemap(vec3(1));

  // Gamma correction
  gl_FragColor.rgb = pow(gl_FragColor.rgb, vec3(1.0 / 2.2));

}
