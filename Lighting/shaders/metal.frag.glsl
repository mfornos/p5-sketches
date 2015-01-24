// --------------------------------------------
// Metal Shader
// --------------------------------------------

#define PI 3.14159265358979323846264

uniform sampler2D texture;

uniform float Ka;
uniform float Kd;
uniform float Ks;

uniform float gamma;
uniform float exposure;
uniform float fresnel;
uniform float albedo;

uniform float transmitMin;
uniform float transmitMax;

varying vec3 Ca;
varying vec3 Cd;
varying vec3 Cs;

varying vec3 N;
varying vec3 P;
varying vec3 V;
varying vec3 L;

varying float I;
varying float roughness;

const float thinness = 3.;


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

float orenNayarDiffuse(
  vec3 lightDirection,
  vec3 viewDirection,
  vec3 surfaceNormal,
  float roughness,
  float albedo ) 
{
  
  float LdotV = dot( lightDirection, viewDirection );
  float NdotL = dot( lightDirection, surfaceNormal );
  float NdotV = dot( surfaceNormal, viewDirection );

  float s = LdotV - NdotL * NdotV;
  float t = mix( 1.0, max( NdotL, NdotV ), step( 0.0, s ) );

  float sigma2 = roughness * roughness;
  float A = 1.0 + sigma2 * ( albedo / ( sigma2 + 0.13 ) + 0.5 / ( sigma2 + 0.33 ) );
  float B = 0.45 * sigma2 / ( sigma2 + 0.09 );

  return albedo * max( 0.0, NdotL ) * ( A + B * s / t ) / PI;
}

void main(  )
{ 
  vec3 l = normalize( L );
  vec3 n = normalize( N );
  vec3 v = normalize( V );

  float diffuse = orenNayarDiffuse( l, v, n, roughness, albedo );
  float specular = ggxSpecular( l, v, n, roughness, fresnel );
   
  vec3 b = Ca * Ka + I * Cd * diffuse * Kd;

  float t1 = transmitMax * ( 1. - pow( 1. - n.z, thinness ) );
  vec3 r = reflect( -v, n );
  float m = 2.0 * sqrt(  r.x*r.x + r.y*r.y + ( r.z+1.0 )*( r.z+1.0 )  );
  vec4 env = texture2D( texture, vec2( r.x / m + 0.5, r.y / m + 0.5 ) );
  float extinction = 5.;
  b += I * exp( -extinction *
                 ( 1. - transmitMin - ( ( 1. - t1 ) * b + t1 * env.rgb ) ) ) 
            * diffuse;
  b += I * Cs * specular * Ks;

  // Tone mapping
  b = tonemap( b * exposure ) / tonemap( vec3( 1 ) );

  // Gamma correction
  b = pow(  b, vec3( 1.0 / gamma )  );

  gl_FragColor = vec4( clamp( b, vec3( 0 ), vec3( 1 ) ), 1. );
}
