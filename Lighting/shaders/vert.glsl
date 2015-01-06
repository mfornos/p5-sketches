#define PROCESSING_LIGHT_SHADER

uniform mat4 modelviewMatrix;
uniform mat4 transformMatrix;
uniform mat3 normalMatrix;

uniform vec3 LightPos;

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

varying vec3 AmbientColour = ambient.rgb;
varying vec3 DiffuseColour = color.rgb;
varying vec3 SpecularColour = specular.rgb;
varying float Roughness = 1.001 - shininess;

void main()
{ 
  gl_Position = transformMatrix * position;

  N = normalize(normalMatrix * normal);
  P = position.xyz;
  V = -vec3(modelviewMatrix * position);
  L = vec3(modelviewMatrix * (vec4(LightPos,1) - position));
}
