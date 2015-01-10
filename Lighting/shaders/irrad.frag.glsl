// --------------------------------------------
// Irradiance Shader
// --------------------------------------------

#define PI 3.14159265358979323846264

uniform float Ka;
uniform float Kd;
uniform float Ks;
uniform float Ke;

uniform float gamma;
uniform float exposure;
uniform float fresnel;
uniform float albedo;

uniform vec3 bgColor;
uniform vec2 resolution;

varying vec3 Ca;
varying vec3 Cs;
varying vec3 Cd;
varying vec3 Ce;

varying vec3 N;
varying vec3 P;
varying vec3 V;
varying vec3 L;

varying float I;
varying float roughness;

mat4 gracered = mat4( 
  0.009098, -0.004780,  0.024033, -0.014947,
 -0.004780, -0.009098, -0.011258,  0.020210,
  0.024033, -0.011258, -0.011570, -0.017383, 
 -0.014947,  0.020210, -0.017383,  0.073787  );

mat4 gracegreen = mat4( 
  -0.002331, -0.002184,  0.009201, -0.002846,
  -0.002184,  0.002331, -0.009611,  0.017903,
   0.009201, -0.009611, -0.007038, -0.009331,
  -0.002846,  0.017903, -0.009331,  0.041083  );

mat4 graceblue = mat4( 
  -0.013032, -0.005248,  0.005970,  0.000483,
  -0.005248,  0.013032, -0.020370,  0.030949,
   0.005970, -0.020370, -0.010948, -0.013784,
   0.000483,  0.030949, -0.013784,  0.051648  );


vec3 tonemap( vec3 x )
{
  float A = 0.15;
  float B = 0.50;
  float C = 0.10;
  float D = 0.20;
  float E = 0.02;
  float F = 0.30;

  return ( ( x*( A*x+C*B )+D*E )/( x*( A*x+B )+D*F ) )-E/F;
}

float G1V( float dotNV, float k )
{
  return 1.0/( dotNV*( 1.0-k )+k );
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

float irradmat( mat4 M, vec3 v )
{
    vec4 n = vec4( v, 1 );
    return dot( n, M * n );
}

float orenNayarDiffuse( 
  vec3 l,
  vec3 v,
  vec3 n,
  float roughness,
  float albedo ) 
{
  
  float LdotV = dot( l, v );
  float NdotL = dot( n, l );
  float NdotV = dot( n, v );

  float s = LdotV - NdotL * NdotV;
  float t = mix( 1.0, max( NdotL, NdotV ), step( 0.0, s ) );

  float sigma2 = roughness * roughness;
  float A = 1.0 + sigma2 * ( albedo / ( sigma2 + 0.13 ) + 0.5 / ( sigma2 + 0.33 ) );
  float B = 0.45 * sigma2 / ( sigma2 + 0.09 );

  return albedo * max( 0.0, NdotL ) * ( A + B * s / t ) / PI;
}

void main(  )
{
  vec3 l = normalize( L ); // Light direction
  vec3 n = normalize( N ); // Surface normal
  vec3 v = normalize( V ); // View direction

  float diffuse = orenNayarDiffuse( l, v, n, roughness, albedo );

  // Irradiance
  vec3 irrad = vec3(  
     albedo * irradmat( gracered, n ),
     albedo * irradmat( gracegreen, n ),
     albedo * irradmat( graceblue, n ) );

  vec3 b = Ca * Ka + I * ( Cd * Kd * diffuse
           + Cs * Ks * ggxSpecular( l, v, n, roughness, fresnel ) );

  float extinction = 15.;
  b += exp( -extinction * ( irrad * 10. ) ) * diffuse;

  // Tone Mapping
  b = tonemap( b * exposure ) / tonemap( vec3( 1 ) );

  // Gamma correction
  b = pow( b, vec3( 1.0 / gamma ) );

  gl_FragColor = vec4( clamp( b, vec3( 0 ), vec3( 1 ) ), 1. );
}

