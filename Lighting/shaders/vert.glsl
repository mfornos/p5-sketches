#define PROCESSING_LIGHT_SHADER

uniform mat4 modelviewMatrix;
uniform mat4 transformMatrix;
uniform mat3 normalMatrix;

uniform vec4 lightPosition;
uniform vec3 lightNormal;
uniform vec3 lightSpot;
uniform vec3 lightFalloff;

attribute vec4 position;
attribute vec4 color;
attribute vec3 normal;

attribute vec4 ambient;
attribute vec4 specular;
attribute vec4 emissive;
attribute float shininess;

varying vec3 N;
varying vec3 P;
varying vec3 V;
varying vec3 L;
varying float spotf;
varying float falloff;

varying vec3 AmbientColour = ambient.rgb;
varying vec3 DiffuseColour = color.rgb;
varying vec3 SpecularColour = specular.rgb;
varying float Roughness = 1.001 - shininess;

float spotFactor(vec3 lightPos, vec3 vertPos, vec3 lightNorm, float minCos, float spotExp) {
  vec3 lpv = normalize(lightPos - vertPos);
  vec3 nln = -1. * lightNorm;
  float spotCos = dot(nln, lpv);
  return spotCos <= minCos ? .0 : pow(spotCos, spotExp);
}

float falloffFactor(vec3 lightPos, vec3 vertPos, vec3 coeff) {
  vec3 lpv = lightPos - vertPos;
  vec3 dist = vec3(1.);
  dist.z = dot(lpv, lpv);
  dist.y = sqrt(dist.z);
  return 1. / dot(dist, coeff);
}

void main()
{ 
  gl_Position = transformMatrix * position;
  
  vec3 v = vec3(modelviewMatrix * position);
  N = normalize(normalMatrix * normal);
  P = position.xyz;
  V = -v;
  L = lightPosition.xyz - v;

  float spotCos = lightSpot.x;
  float spotExp = lightSpot.y;
  falloff = falloffFactor(lightPosition.xyz, v, lightFalloff);
  spotf = spotExp > 0. ? spotFactor(lightPosition.xyz, v, lightNormal, 
                                              spotCos, spotExp) : 1.;
}
