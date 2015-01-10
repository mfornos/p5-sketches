#define PROCESSING_LIGHT_SHADER

#define PI 3.14159265358979323846264

uniform mat4 modelviewMatrix;
uniform mat4 transformMatrix;
uniform mat3 normalMatrix;

uniform vec4 lightPosition;
uniform vec3 lightNormal;
uniform vec3 bgColor;
uniform float Lr;

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

varying vec3 Ca = bgColor.rgb;
varying vec3 Cd = color.rgb;
varying vec3 Cs = specular.rgb;
varying float roughness = 1. - shininess;

void main(  )
{ 
  gl_Position = transformMatrix * position;
  
  vec3 v = vec3( modelviewMatrix * position );
  
  N = normalize( normalMatrix * normal );
  P = position.xyz;
  V = -v;
  
  L = lightPosition.xyz - P;
  
  // Point light
  float dist = length(L);
  L /= dist;

  float r = Lr * 10.;
  float d = max(dist - r, 0.);
  float dn = d / r + 1.;
  I = 1. / ( dn * dn );
}
