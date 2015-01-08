#define PROCESSING_LIGHT_SHADER

uniform mat4 modelviewMatrix;
uniform mat4 transformMatrix;
uniform mat3 normalMatrix;

uniform vec4 lightPosition;
uniform vec3 lightNormal;
uniform vec3 BgColor;

attribute vec4 position;
attribute vec4 color;
attribute vec3 normal;

attribute vec4 ambient;
attribute vec4 specular;
attribute vec4 emissive;

attribute float shininess;

varying vec3  N;
varying vec3  P;
varying vec3  V;
varying vec3  L;
varying float I;

varying vec3 aC = BgColor.rgb;
varying vec3 dC = color.rgb;
varying vec3 sC = specular.rgb;
varying float Roughness = 1.001 - shininess;

float attenuation(vec3 lightPos, vec3 vertPos) {
  float radius = 1000.;
  float dist = distance(vertPos, lightPos);
  float att = clamp(1.0 - dist*dist/(radius*radius), 0.0, 1.0);
  return att * att;
}

void main()
{ 
  gl_Position = transformMatrix * position;
  
  vec3 v = vec3(modelviewMatrix * position);
  N = normalize(normalMatrix * normal);
  P = position.xyz;
  V = -v;
  L = lightPosition.xyz - v;
  float W = dot(-normalize(L), vec3(0,0.5,1));
  I = max(0.75 * (W*W*W*W*W*W), 0.);
}
