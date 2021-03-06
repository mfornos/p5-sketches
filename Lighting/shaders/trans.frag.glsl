// --------------------------------------------
// Transmittance Shader
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
uniform float strength;

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

vec3 tonemap(vec3 x)
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
	float dotNV = clamp(dot(N,V), 0., 1.);
	float dotNH = clamp(dot(N,H), 0., 1.);
	float dotLH = clamp(dot(L,H), 0., 1.);

	float F, D, vis;

	// D
	float alphaSqr = alpha*alpha;
	float pi = 3.14159;
	float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0;
	D = alphaSqr/(pi * denom * denom);

	// F
	float dotLH5 = pow(1.0-dotLH,5.);
	F = F0 + (1.0-F0)*(dotLH5);

	// V
	float k = alpha/2.0;
	vis = G1V(dotNL,k)*G1V(dotNV,k);

	float specular = dotNL * D * F * vis;
	return specular;
}

float ggxSpecularOpt1(vec3 L, vec3 V, vec3 N, float roughness, float F0)
{
	float alpha = roughness*roughness;

	vec3 H = normalize(V+L);

	float dotNL = clamp(dot(N,L), 0., 1.);
	float dotNH = clamp(dot(N,H), 0., 1.);
	float dotLH = clamp(dot(L,H), 0., 1.);

	float F, D, vis;

	// D
	float alphaSqr = alpha*alpha;
	float pi = 3.14159;
	float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0;
	D = alphaSqr/(pi * denom * denom);

	// F
	float dotLH5 = pow(1.0-dotLH,5.);
	F = F0 + (1.0-F0)*(dotLH5);

	// V
	float k = alpha/2.0;
	vis = G1V(dotLH,k)*G1V(dotLH,k);

	float specular = dotNL * D * F * vis;
	return specular;
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

// NOTE: not a real light in/out distance
float distance(vec3 p, vec3 n, vec3 l) 
{
  // Shrink the position to avoid artifacts on the silhouette:
  vec3 sp = p - 0.005 * n;

  vec3 posL = sp * normalize(L-P);

  // For testing without shadow map
  // Fetch depth from the shadow map:
  // (Depth from shadow maps is expected to be linear)
  float depth = ( 2.0 * gl_FragCoord.z - gl_DepthRange.near - gl_DepthRange.far ) /
                ( gl_DepthRange.far - gl_DepthRange.near );

  float d1 = depth * -N.z; // shwmaps[i].Sample(sampler, posL.xy / posL.w);
  float d2 = posL.z;

  // Calculate the difference:
  return abs(d1 - d2);
}

vec3 T(float s) {
  return vec3(0.233, 0.455, 0.649) * exp(-s * s / 0.0064) +
         vec3(0.1,   0.336, 0.344) * exp(-s * s / 0.0484) +
         vec3(0.118, 0.198, 0.0)   * exp(-s * s / 0.187)  +
         vec3(0.113, 0.007, 0.007) * exp(-s * s / 0.567)  +
         vec3(0.358, 0.004, 0.0)   * exp(-s * s / 1.99)   +
         vec3(0.078, 0.0,   0.0)   * exp(-s * s / 7.41);
}

void main()
{ 
  float waxiness = 0.15;
  vec3 l = normalize( L ); // Light direction
  vec3 n = normalize( N ); // Surface normal
  vec3 v = normalize( V ); // View direction
  vec3 p = normalize( P );

  float diffuse = orenNayarDiffuse( l, v, n, roughness, albedo );
  diffuse = waxiness + (1. - waxiness) * diffuse;
  float specular = diffuse <= 0.0 ? 0.0 : ggxSpecularOpt1(l, v, n, roughness, fresnel);
  vec3 b = Ca * Ka + I * (Cd * diffuse * Kd + Cs * specular * Ks);

  // Estimate the irradiance on the back
  float irradiance = max( 0.3 + dot( -n, l ), 0.0 );

  // Calculate the distance traveled by the light inside of the object
  float s = distance( p, n, l ) / strength;

  float R0 = 1. / 2.4;
  float refraction = R0 + (1.0 - R0) * pow((1.0 - dot(-p, n)), 5.0);

  // Calculate transmitted light
  vec3 transmittance = T( s ) * Kd * Cd * albedo * irradiance * refraction;

  // Add the contribution
  b += I * transmittance;

  // Tone mapping
  b = tonemap(b * exposure) / tonemap(vec3(1));

  // Gamma correction
  b = pow( b, vec3(1.0 / gamma) );

  gl_FragColor = vec4(clamp(b, vec3(0), vec3(1)), 1.0);
}
