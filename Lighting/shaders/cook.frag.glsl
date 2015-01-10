// --------------------------------------------
// Cook Torrance Shader
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

float beckmannDistribution( float x, float roughness ) 
{
  float NdotH = max( x, 0.0001 );
  float cos2Alpha = NdotH * NdotH;
  float tan2Alpha = ( cos2Alpha - 1.0 ) / cos2Alpha;
  float roughness2 = roughness * roughness;
  float denom = PI * roughness2 * cos2Alpha * cos2Alpha;
  return exp( tan2Alpha / roughness2 ) / denom;
}

float cookTorranceSpecular( 
  vec3 l,
  vec3 v,
  vec3 n,
  float roughness,
  float fresnel )
{

  float VdotN = max( dot( v, n ), 0.0 );
  float LdotN = max( dot( l, n ), 0.0 );

  //Half angle vector
  vec3 H = normalize( l + v );

  //Geometric term
  float NdotH = max( dot( n, H ), 0.0 );
  float VdotH = max( dot( v, H ), 0.000001 );
  float LdotH = max( dot( l, H ), 0.000001 );
  float G1 = ( 2.0 * NdotH * VdotN ) / VdotH;
  float G2 = ( 2.0 * NdotH * LdotN ) / LdotH;
  float G = min( 1.0, min( G1, G2 ) );
  
  //Distribution term
  float D = beckmannDistribution( NdotH, roughness );

  //Fresnel term
  float F = pow( 1.0 - VdotN, fresnel );

  //Multiply terms and done
  return  G * F * D / max( 3.14159265 * VdotN, 0.000001 );
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
  // vec3 h = normalize( l + v );

  float diffuse = orenNayarDiffuse( l, v, n, roughness, albedo );
  float specular = cookTorranceSpecular( l, v, n, roughness, fresnel );
    
  vec3 b = Ca * Ka + I * ( Cd * Kd * diffuse + Cs * Ks * specular );

  // Tone mapping
  b = tonemap( b * exposure ) / tonemap( vec3( 1 ) );

  // Gamma correction
  b = pow(  b, vec3( 1.0 / gamma )  );

  gl_FragColor = vec4( clamp( b, vec3( 0 ), vec3( 1 ) ), 1. );
}
