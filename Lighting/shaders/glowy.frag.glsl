// --------------------------------------------
// Glowy Shader
// --------------------------------------------
// Fake SSS, duh!
// 

#define PI 3.14159265358979323846264

uniform float Ka;
uniform float Kd;
uniform float Ks;

uniform float gamma;
uniform float exposure;
uniform float fresnel;
uniform float waxiness;
uniform vec3 bgColor;
uniform vec2 resolution;

varying vec3 Ca;
varying vec3 Cd;
varying vec3 Cs;

varying vec3 N;
varying vec3 P;
varying vec3 V;
varying vec3 L;

varying float I;
varying float roughness;

const float sharpness = 0.5;
const vec3 LIGHT_COLOR = vec3( .9, .9, 1 );

vec3 tonemap( vec3 x )
{
  float A = 0.15;
  float B = 0.50;
  float C = 0.10;
  float D = 0.20;
  float E = 0.02;
  float F = 0.30;

  return ( ( x*( A*x+C*B )+D*E ) / ( x*( A*x+B )+D*F ) ) - E / F;
}

float G1V( float dotNV, float k )
{
  return 1.0 / ( dotNV * ( 1.0-k ) + k );
}

float ggxSpecular( vec3 L, vec3 V, vec3 N, float roughness, float F0 )
{
  float alpha = roughness*roughness;

  vec3 H = normalize( V+L );

  float dotNL = clamp( dot( N,L ), 0., 1. );
  float dotNH = clamp( dot( N,H ), 0., 1. );
  float dotLH = clamp( dot( L,H ), 0., 1. );

  float F, D, vis;

  // D
  float alphaSqr = alpha*alpha;
  float denom = dotNH * dotNH *( alphaSqr-1.0 ) + 1.0;
  D = alphaSqr/( PI * denom * denom );

  // F
  float dotLH5 = pow( 1.0-dotLH,5. );
  F = F0 + ( 1.0-F0 )*( dotLH5 );

  // V
  float k = alpha/2.0;
  vis = G1V( dotLH,k )*G1V( dotLH,k );

  float specular = dotNL * D * F * vis;
  return specular;
}

void main(  )
{ 
  vec3 l = normalize( L );
  vec3 n = normalize( N );
  vec3 v = normalize( V );

  vec3 ambient = Ca * Ka;
  vec3 diffuse = I * LIGHT_COLOR * Cd * Kd
                           * ( waxiness + ( 1. - waxiness )
                           * max( 0., dot( n, l ) ) );
  vec3 specular = I * LIGHT_COLOR 
                            * Cs * Ks
                            * ggxSpecular( l, v, n, roughness, fresnel );

  // Rim silhouette
  float w = 0.18 * ( 1.0 - sharpness );
  float rim = 1. - abs( dot( v, n ) ); // abs illuminate 2 sides

  vec4 b1 = vec4( rim * ( ambient + diffuse ), 1. );
  b1 += vec4( rim * diffuse, 1.);
  b1 *= vec4( ambient + diffuse + specular, rim );
  b1 += vec4( diffuse + specular, 1.);

  vec3 b = b1.rgb;

  // Tone mapping
  b = tonemap( b * exposure ) / tonemap( vec3( 1 ) );

  // Gamma correction
  b = pow(  b, vec3( 1.0 / gamma )  );

  gl_FragColor = vec4( clamp( b, vec3( 0 ), vec3( 1 ) ), b1.w );
}

